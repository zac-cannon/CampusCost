import 'package:campuscost_app/screens/filters_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../services/college_service.dart';
import 'college_details_screen.dart';
import '../widgets/college_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'dart:ui' as ui;
import 'dart:typed_data';

//helper function for resizing pins:
Future<Uint8List> _resizeImage(Uint8List data, {required int width}) async {
  final codec = await ui.instantiateImageCodec(data, targetWidth: width);
  final frame = await codec.getNextFrame();
  final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}


class CollegeSearchScreen extends StatefulWidget {
  @override
  _CollegeSearchScreenState createState() => _CollegeSearchScreenState();
}

class _CollegeSearchScreenState extends State<CollegeSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _colleges = [];
  Set<String> _favoriteIds = {}; // Keep track of fav college IDs
  bool _isLoading = false;
  int _selectedMinNetCost = 0;
  int _selectedMaxNetCost= 100000;
  double _selectedMaxAcceptanceRate = 1.0;
  double _selectedMinAcceptanceRate = 0;
  bool _selectedIsPublic = true;
  bool _selectedIsPrivate = true;
  bool _isMapView = true;
  String _selectedState = '';
  String? _selectedCollegeId;
  List<int> _selectedDegreeTypes = [1, 2, 3]; // Default: all selected
  late BitmapDescriptor _defaultMarker;
  late BitmapDescriptor _highlightMarker;
  bool _markersLoaded = false;
  GoogleMapController? _mapController;
  final ScrollController _scrollController = ScrollController();
  late Map<String, dynamic> _loadedFilterSnapshot;

  final List<String> _usStates = [
    '', 'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS',
    'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC',
    'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];


  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _loadSavedFilters();
  }


  Future<Map<String, dynamic>> _refreshFiltersIfChanged() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _currentFilterState(); // fallback to current if user not logged in

    final prefsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('filters')
        .get();

    if (prefsDoc.exists) {
      final prefs = prefsDoc.data()!;
      final updated = {
        'maxNetCost': (prefs['maxNetCost'] ?? 100000).toInt(),
        'isPublic': prefs['isPublic'] ?? true,
        'isPrivate': prefs['isPrivate'] ?? true,
        'minAcceptanceRate': (prefs['minAcceptanceRate'] ?? 0.0).toDouble(),
        'state': prefs['state'] ?? '',
        'degreeTypes': List<int>.from(prefs['degreeTypes'] ?? [1, 2, 3]),
      };

      if (updated.toString() != _loadedFilterSnapshot.toString()) {
        setState(() {
          _selectedMaxNetCost = updated['maxNetCost'];
          _selectedMinNetCost = updated['minNetCost'];
          _selectedIsPublic = updated['isPublic'];
          _selectedIsPrivate = updated['isPrivate'];
          _selectedMinAcceptanceRate = updated['minAcceptanceRate'];
          _selectedMaxAcceptanceRate = updated['maxAcceptanceRate'];
          _selectedState = updated['state'];
          _selectedDegreeTypes = updated['degreeTypes'];
          _loadedFilterSnapshot = updated;
        });
      }

      return updated;
    }

    return _currentFilterState(); // fallback if no saved filters
  }



  Map<String, dynamic> _currentFilterState() {
    return {
      'maxNetCost': _selectedMaxNetCost,
      'minNetCost': _selectedMinNetCost,
      'isPublic': _selectedIsPublic,
      'isPrivate': _selectedIsPrivate,
      'minAcceptanceRate': _selectedMinAcceptanceRate,
      'state': _selectedState,
      'degreeTypes': _selectedDegreeTypes,
    };
  }
// Check if a college name or state is entered in the search, 
// warn the user of the long wait times if that is NOT the case
  Future<bool> _warningCheck() async {
    final collegeName = _controller.text.trim();
    if (collegeName.isEmpty && _selectedState.isEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Warning"),
          content: Text("Searching without a college name or state may take over a minute to load.\nDo you want to continue?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Continue"),
            ),
          ],
        ),
      );
      return result == true;
    }
    return true;
  }


//Load the default (blue) marker icons and the highlighted/selected (red) marker icons
  Future<void> _loadMarkerIcons() async {
    final ByteData blueData = await rootBundle.load('assets/bluemarker.png');
    final Uint8List blueBytes = blueData.buffer.asUint8List();
    final Uint8List scaledBlue = await _resizeImage(blueBytes, width: 20);

    _defaultMarker = BitmapDescriptor.fromBytes(scaledBlue);
    _highlightMarker = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue); 
    
    setState(() {
      _markersLoaded = true;
    });
  }
// Main college search: starts with name AND/OR state based fetch from College Scorecard API
  void _searchCollege() async {
    
  // Warn user if no college name or state is selected (to prevent unwanted long load times)
    final shouldProceed = await _warningCheck();
    if (!shouldProceed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch colleges server side (filtered directly by API via name and/or state)
      final results = await CollegeService.fetchColleges(
        collegeName: _controller.text.trim(),
        state: _selectedState,
      );
      // check if user is using default filters (no extra filtering applied)
      final filtersAreDefault = _selectedMaxNetCost == 100000 &&
        _selectedMinNetCost == 0 &&
        _selectedIsPublic == true &&
        _selectedIsPrivate == true &&
        _selectedMinAcceptanceRate == 0 &&
        _selectedMaxAcceptanceRate == 1.0 &&
        _selectedDegreeTypes.length == 3 &&
        _selectedDegreeTypes.contains(1) &&
        _selectedDegreeTypes.contains(2) &&
        _selectedDegreeTypes.contains(3);

    final List<dynamic> finalList = filtersAreDefault
        ? results //if filters default, fetch ALL colleges from server side filter (DO NOT FILTER CLIENT SIDE)
        : results.where((college) { //if custom filters are applied, FILTER CLIENT SIDE
            final netCost = college["latest.cost.avg_net_price.overall"] ?? 0;
            final ownership = college["school.ownership"];
            final acceptanceRate = college["latest.admissions.admission_rate.overall"] ?? 0.0;
            final degreeType = college["school.degrees_awarded.predominant"];

            final matchesNetCost = (netCost <= _selectedMaxNetCost) && (netCost >= _selectedMinNetCost);
            final matchesOwnership =
              (_selectedIsPublic && ownership == 1) || (_selectedIsPrivate && (ownership == 2 || ownership == 3));
            final matchesAcceptance = 
              (acceptanceRate >= _selectedMinAcceptanceRate) && (acceptanceRate <= _selectedMaxAcceptanceRate);
            final matchesDegreeType = _selectedDegreeTypes.contains(degreeType);

            return matchesNetCost && matchesOwnership && matchesAcceptance && matchesDegreeType;
          }).toList();

      // Fetch the user's saved favorite colleges
      final favorites = await FavoriteService.fetchFavorites();

      setState(() {
        // update the search results with final filters colleges
        _colleges = finalList;

        // Convert list of favorite colleges into a set of their IDs for quick lookup
        _favoriteIds = favorites.map((c) => c['id'].toString()).toSet(); 
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data. Please try again.")));
    }

    setState(() {
      _isLoading = false;
    });
  }
  Future<void> _loadSavedFilters() async {
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('filters')
        .get();
      
    if (doc.exists) {
      final prefs = doc.data()!;
      setState(() {
        _selectedMinNetCost = (prefs['minNetCost'] ?? 0).toInt();
        _selectedMaxNetCost = (prefs['maxNetCost'] ?? 100000).toInt();
        _selectedMinAcceptanceRate = (prefs['minAcceptanceRate'] ?? 0.0).toDouble();
        _selectedMaxAcceptanceRate = (prefs['maxAcceptanceRate'] ?? 1.0).toDouble();
        _selectedIsPublic = prefs['isPublic'] ?? true;
        _selectedIsPrivate = prefs['isPrivate'] ?? true;        
        _selectedState = prefs['state'] ?? '';
        _selectedDegreeTypes = List<int>.from(prefs['degreeTypes'] ?? [1, 2, 3]);

        _loadedFilterSnapshot = _currentFilterState(); // Save snapshot

      });
    }
  }

  //Call the 'Favorite Service' to add/remove a college from favorites
  Future<void> _toggleFavorite(Map<String, dynamic> college) async {
    final collegeId = college['id'].toString();
    final user = FirebaseAuth.instance.currentUser;


    if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You must be logged in to save favorites.")),
    );
    return; // Stop here if not logged in
  }

    if (_favoriteIds.contains(collegeId)) {
      await FavoriteService.removeFromFavorites(collegeId);
      setState(() {
        _favoriteIds.remove(collegeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${college["school.name"]} removed from favorites")),
      );
    } else {
      await FavoriteService.saveToFavorites(college);
      setState(() {
        _favoriteIds.add(collegeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${college["school.name"]} added to favorites")),
      );
    }
  }
  //Create the interactive map view with college pins
  Widget _buildMapView() {
  //LOAD MARKERS:
   if (!_markersLoaded) {
      return Center(child: CircularProgressIndicator());
    }
    //Gather college & location data 
    final markers = Set<Marker>.of(_colleges.map((college) {
    final lat = college["location.lat"];
    final lon = college["location.lon"];
    final id = college["id"].toString();

    // will not display pin if location does not exist for a college
    if (lat == null || lon == null) return null;

    final isSelected = _selectedCollegeId == id;
    return Marker(
      markerId: MarkerId(isSelected ? 'selected-$id' : 'default-$id'),
      position: LatLng(lat, lon),
      icon: isSelected ? _highlightMarker : _defaultMarker, // If selected, change marker icon
      zIndex: isSelected ? 2.0 : 1.0, // MOVE TO FRONT (selected marker)
      onTap: () { // Assign selected college when user clicks on a pin
        setState(() {
          _selectedCollegeId = id;
        });
        // Scroll to college in list view when selected by pin:
        final index = _colleges.indexWhere((c) => c['id'].toString() == id);
        if (index != -1) {
          _scrollController.animateTo(
            index * 187.0, // Assuming each CollegeTile is ~187px tall
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      },

      //Open the college details screen if user clicks on pin info window
      infoWindow: InfoWindow(
        title: college["school.name"],
        snippet: "(Click here to view details)",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CollegeDetailsScreen(college: college),
            ),
          );
        },
      ),
    );

  }).whereType<Marker>());

  //LOAD MAP:
    return GoogleMap(
      onMapCreated: (controller) {
        if (mounted) {
          _mapController = controller;
        }
      },
      //Initial camera position is overview of USA
      initialCameraPosition: CameraPosition(
        target: LatLng(39.8283, -98.5795),
        zoom: 4.0,
      ),
      markers: markers,
      onTap: (_) {
        setState(() => _selectedCollegeId = null);
      },
    );


  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.arrow_upward),
              title: Text('Net Cost: Low to High'),
              onTap: () {
                setState(() {
                  _colleges.sort((a, b) =>
                    (a["latest.cost.avg_net_price.overall"] ?? 999999)
                        .compareTo(b["latest.cost.avg_net_price.overall"] ?? 999999));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_downward),
              title: Text('Net Cost: High to Low'),
              onTap: () {
                setState(() {
                  _colleges.sort((a, b) =>
                    (b["latest.cost.avg_net_price.overall"] ?? 0)
                        .compareTo(a["latest.cost.avg_net_price.overall"] ?? 0));
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Icon(Icons.school),
              title: Text('Acceptance Rate'),
              onTap: () {
                setState(() {
                  _colleges.sort((a, b) =>
                    (b["latest.admissions.admission_rate.overall"] ?? 0.0)
                        .compareTo(a["latest.admissions.admission_rate.overall"] ?? 0.0));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Student Size'),
              onTap: () {
                setState(() {
                  _colleges.sort((a, b) =>
                    (b["latest.student.size"] ?? 0).compareTo(a["latest.student.size"] ?? 0));
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
}


 Widget _buildListView() {
  //If no college has been searched, display text:
  if (_controller.text.isEmpty && _colleges.isEmpty) {
    return Center(
      child: Text(
        "Start by searching for a college!",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );

  //If search could not find any colleges, display text:
  } else if (_controller.text.isNotEmpty && _colleges.isEmpty) {
    return Center(
      child: Text(
        "No colleges found.\nTry adjusting your search or filters.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 72, 71, 71)),
      ),
    );
  }

  if (_isMapView) { // Build list in map view (list on side)
    // Return the scrollable vertical list 
    return ListView.builder(
      //build a list of colleges with college tile widget
      controller: _scrollController,
      itemCount: _colleges.length,
      itemBuilder: (context, index) {
        final college = _colleges[index];
        final collegeId = college['id'].toString();
        final isFavorite = _favoriteIds.contains(collegeId);

        return CollegeTile(
          college: college,
          isFavorite: isFavorite,
          isSelected: _selectedCollegeId == collegeId,
          onFavoriteToggle: () => _toggleFavorite(college),
          onTap: () async {
            setState(() {
              _selectedCollegeId = collegeId;
            });

            final lat = college["location.lat"];
            final lon = college["location.lon"];
            
            //Animate the mapview camera to the new location when a college is selected
            if (lat != null && lon != null && _mapController != null) {
              try {
                await _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(lat, lon), 8),
                );
              } catch (e) {
                print('animateCamera failed: $e');
              }
            }
          },
        );
      },
    );
  } else {
    // Return a grid for non-map view
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 1.5, // Width / Height ratio
      ),
      itemCount: _colleges.length,
      itemBuilder: (context, index) {
        final college = _colleges[index];
        final collegeId = college['id'].toString();
        final isFavorite = _favoriteIds.contains(collegeId);

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 175,
              child: CollegeTile(
                college: college,
                isFavorite: isFavorite,
                isSelected: _selectedCollegeId == collegeId,
                onFavoriteToggle: () => _toggleFavorite(college),
                onTap: () {
                  setState(() {
                    _selectedCollegeId = collegeId;
                  });
                },
              ),
            );
          },
        );
      },
    );

  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Row( //College search box & state dropdown:
                  children: [
                    Expanded(
                      flex: 2,
                      //College search box field:
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _searchCollege(), // Enter key triggers search
                        decoration: InputDecoration(
                          hintText: "Enter college name",
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
                          //Clear text college search box field button:
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade700),
                                  onPressed: () {
                                    setState(() {
                                      _controller.clear();
                                    });
                                  },
                                )
                              : null,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // State dropdown:
                    Container(
                      width: 140,
                      height: 48,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedState.isNotEmpty ? _selectedState : null,
                          icon: Icon(Icons.location_on, color: Colors.grey.shade700),
                          hint: Text("Select State"),
                          items: _usStates.map((state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state.isEmpty ? "Any" : state),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedState = value ?? '');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Buttons for search, filter, and sort
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: _searchCollege,
                        child: Text("Search"),
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CollegeFiltersScreen(
                                initialMaxNetCost: _selectedMaxNetCost,
                                initialMinNetCost: _selectedMinNetCost,
                                initialIsPublic: _selectedIsPublic,
                                initialIsPrivate: _selectedIsPrivate,
                                initialMinAcceptanceRate: _selectedMinAcceptanceRate,
                                initialMaxAcceptanceRate: _selectedMaxAcceptanceRate,
                                initialState: _selectedState,
                                initialDegreeTypes: _selectedDegreeTypes,
                              ),
                            ),
                          );

                          if (result != null && result is Map) {
                            _selectedMinNetCost = result['minNetCost'];
                            _selectedMaxNetCost = result['maxNetCost'];
                            _selectedIsPublic = result['isPublic'];
                            _selectedIsPrivate = result['isPrivate'];
                            _selectedMaxAcceptanceRate = result['maxAcceptanceRate'] ?? 1.0;
                            _selectedMinAcceptanceRate = result['minAcceptanceRate'] ?? 0.0;
                            _selectedState = result['state'] ?? '';
                            _selectedDegreeTypes = List<int>.from(result['degreeTypes'] ?? [1, 2, 3]);

                            final shouldProceed = await _warningCheck();
                            if (!shouldProceed) return;

                            setState(() => _isLoading = true);

                            try {
                              final results = await CollegeService.fetchColleges(
                                collegeName: _controller.text.trim(),
                                state: _selectedState,
                              );

                              final filtered = results.where((college) {
                                final netCost = college["latest.cost.avg_net_price.overall"] ?? 0;
                                final matchesNetCost = (netCost <= _selectedMaxNetCost) && (netCost >= _selectedMinNetCost);

                                final ownership = college["school.ownership"];
                                final degreeType = college["school.degrees_awarded.predominant"];

                                final matchesOwnership =
                                    (_selectedIsPublic && ownership == 1) ||
                                    (_selectedIsPrivate && (ownership == 2 || ownership == 3));
                                final acceptanceRate = college["latest.admissions.admission_rate.overall"] ?? 0.0;
                                final matchesAcceptance = (acceptanceRate >= _selectedMinAcceptanceRate) && (acceptanceRate <= _selectedMaxAcceptanceRate);
                                final matchesDegreeType = _selectedDegreeTypes.contains(degreeType);

                                return matchesNetCost && matchesOwnership && matchesAcceptance && matchesDegreeType;
                              }).toList();

                              final favorites = await FavoriteService.fetchFavorites();

                              setState(() {
                                _colleges = filtered;
                                _favoriteIds = favorites.map((c) => c['id'].toString()).toSet();
                                _isLoading = false;
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error applying filters. Please try again.")));
                              setState(() => _isLoading = false);
                            }

                          }
                        },
                        child: Text("Filters"),
                      ),
                    ),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: _showSortOptions,
                        child: Text("Sort"),
                      ),
                    ),

                    SizedBox(width: 20),
                    // Map view/ Grid view toggle button:
                    Tooltip(
                      message: _isMapView ? "Switch to Grid View" : "Switch to Map View",
                      child: Row(
                        children: [
                          Icon(Icons.map),
                          Switch(
                            value: _isMapView,
                            onChanged: (value) {
                              setState(() {
                                _isMapView = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : Expanded(
                  child: _isMapView
                      ? Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                padding: EdgeInsets.all(12),
                                child: _buildListView(),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildMapView(),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          padding: EdgeInsets.all(12),
                          child: _buildListView(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

