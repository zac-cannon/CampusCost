import 'package:campuscost_app/screens/filters_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../services/college_service.dart';
import 'college_details_screen.dart';
import '../widgets/college_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  int _selectedMaxTuition = 100000;
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

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons(); 
  }

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

  void _searchCollege() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = _selectedState.isNotEmpty
        ? await CollegeService.fetchCollegesByState(_selectedState)
        : await CollegeService.fetchColleges(_controller.text);

      final favorites = await FavoriteService.fetchFavorites();

      setState(() {
        _colleges = results;
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
  //Create google map with college pins
  Widget _buildMapView() {
   if (!_markersLoaded) {
      return Center(child: CircularProgressIndicator());
    }
    final markers = Set<Marker>.of(_colleges.map((college) {
    final lat = college["location.lat"];
    final lon = college["location.lon"];
    final id = college["id"].toString();

    if (lat == null || lon == null) return null;

    final isSelected = _selectedCollegeId == id;
    print("Marker: ${college["school.name"]}, isSelected: $isSelected");

    return Marker(
      markerId: MarkerId(isSelected ? 'selected-$id' : 'default-$id'),
      position: LatLng(lat, lon),
      icon: isSelected ? _highlightMarker : _defaultMarker,
      zIndex: isSelected ? 2.0 : 1.0, // MOVE TO FRONT (selected marker)
      onTap: () {
      setState(() {
        _selectedCollegeId = id;
      });

      final index = _colleges.indexWhere((c) => c['id'].toString() == id);
      if (index != -1) {
        _scrollController.animateTo(
          index * 187.0, // Assuming each CollegeTile is ~187px tall
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    },

    // This triggers when user taps the info window (separate)
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


    return GoogleMap(
      onMapCreated: (controller) {
        if (mounted) {
          _mapController = controller;
        }
      },
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
              title: Text('Tuition: Low to High'),
              onTap: () {
                setState(() {
                  _colleges.sort((a, b) =>
                    (a["latest.cost.tuition.in_state"] ?? 0).compareTo(b["latest.cost.tuition.in_state"] ?? 0));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_downward),
              title: Text('Tuition: High to Low'),
              onTap: () {
                setState(() {
                  _colleges.sort((a, b) =>
                    (b["latest.cost.tuition.in_state"] ?? 0).compareTo(a["latest.cost.tuition.in_state"] ?? 0));
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
  if (_controller.text.isEmpty && _colleges.isEmpty) {
    return Center(
      child: Text(
        "Start by searching for a college!",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  } else if (_controller.text.isNotEmpty && _colleges.isEmpty) {
    return Center(
      child: Text(
        "No colleges found.\nTry adjusting your search or filters.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 72, 71, 71)),
      ),
    );
  }

  if (_isMapView) {
    // Return the scrollable vertical list as before (for side panel)
    return ListView.builder(
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
                TextField(
                  controller: _controller,
                  onSubmitted: (_) => _searchCollege(), // Enter key triggers search
                  decoration: InputDecoration(
                    hintText: "Enter college name",
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
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

                SizedBox(height: 10),

                // Buttons for search and filter
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
                                initialMaxTuition: _selectedMaxTuition,
                                initialIsPublic: _selectedIsPublic,
                                initialIsPrivate: _selectedIsPrivate,
                                initialMinAcceptanceRate: _selectedMinAcceptanceRate,
                                initialState: _selectedState,
                                initialDegreeTypes: _selectedDegreeTypes,
                              ),
                            ),
                          );

                          if (result != null && result is Map) {
                            _selectedMaxTuition = result['maxTuition'];
                            _selectedIsPublic = result['isPublic'];
                            _selectedIsPrivate = result['isPrivate'];
                            _selectedMinAcceptanceRate = result['minAcceptanceRate'] ?? 0.0;
                            _selectedState = result['state'] ?? '';
                            _selectedDegreeTypes = List<int>.from(result['degreeTypes'] ?? [1, 2, 3]);



                            setState(() => _isLoading = true);

                            try {
                              final results = _selectedState.isNotEmpty
                                  ? await CollegeService.fetchCollegesByState(_selectedState)
                                  : await CollegeService.fetchColleges(_controller.text);

                              final filtered = results.where((college) {
                                final tuition = college["latest.cost.tuition.in_state"] ?? 0;
                                final ownership = college["school.ownership"];
                                final matchesTuition = tuition <= _selectedMaxTuition;
                                final degreeType = college["school.degrees_awarded.predominant"];

                                final matchesOwnership =
                                    (_selectedIsPublic && ownership == 1) ||
                                    (_selectedIsPrivate && (ownership == 2 || ownership == 3));
                                final acceptanceRate = college["latest.admissions.admission_rate.overall"] ?? 0.0;
                                final matchesAcceptance = acceptanceRate >= _selectedMinAcceptanceRate;
                                final matchesDegreeType = _selectedDegreeTypes.contains(degreeType);

                                return matchesTuition && matchesOwnership && matchesAcceptance && matchesDegreeType;
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
                    Tooltip(
                      message: _isMapView ? "Switch to List View" : "Switch to Map View",
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

