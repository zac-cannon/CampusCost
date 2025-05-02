import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/college_service.dart';
import '../widgets/college_tile.dart';
import 'college_details_screen.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class SavedCollegesScreen extends StatefulWidget {
  @override
  _SavedCollegesScreenState createState() => _SavedCollegesScreenState();
}

class _SavedCollegesScreenState extends State<SavedCollegesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _selectedCollegeId;
  GoogleMapController? _mapController;
  final ScrollController _scrollController = ScrollController();

  late BitmapDescriptor _defaultMarker;
  late BitmapDescriptor _highlightMarker;
  bool _markersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    final ByteData blueData = await rootBundle.load('assets/bluemarker.png');
    final Uint8List blueBytes = blueData.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(blueBytes, targetWidth: 20);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    final scaledBlue = byteData!.buffer.asUint8List();

    _defaultMarker = BitmapDescriptor.fromBytes(scaledBlue);
    _highlightMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    setState(() => _markersLoaded = true);
  }

  Future<void> _loadFavorites() async {
    //Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _favorites = [];
        _isLoading = false;
      });
      return;
    }

    final uid = CollegeService.getCurrentUserId();
    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites');

    List<Map<String, dynamic>> docs = [];
    try {
      final rankedSnapshot = await favoritesRef.orderBy('rank').get();
      if (rankedSnapshot.docs.isNotEmpty) {
        docs = rankedSnapshot.docs.map((doc) => doc.data()).toList();
      } else {
        final unrankedSnapshot = await favoritesRef.get();
        docs = unrankedSnapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (e) {
      final fallbackSnapshot = await favoritesRef.get();
      docs = fallbackSnapshot.docs.map((doc) => doc.data()).toList();
    }

    final fullFavorites = await Future.wait(
      docs.map((fav) => CollegeService.fetchCollegeById(fav['id'].toString())),
    );
    
    if (!mounted) return;
    setState(() {
      _favorites = fullFavorites;
      _isLoading = false;
    });

    
  }

  Future<void> _saveRanks() async {
    final uid = CollegeService.getCurrentUserId();
    for (int i = 0; i < _favorites.length; i++) {
      final collegeId = _favorites[i]['id'].toString();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(collegeId)
          .update({'rank': i});
    }
  }

  void _confirmRemoveFavorite(String collegeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Favorite'),
        content: Text('Are you sure you want to remove this college from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FavoriteService.removeFromFavorites(collegeId);
              _loadFavorites();
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapListView() {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      itemCount: _favorites.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _favorites.removeAt(oldIndex);
          _favorites.insert(newIndex, item);
        });
        await _saveRanks();
      },
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final college = _favorites[index];
        final collegeId = college['id'].toString();
        return Container(
          key: ValueKey(collegeId),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.drag_handle, color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                child: CollegeTile(
                  college: college,
                  isFavorite: true,
                  isSelected: _selectedCollegeId == collegeId,
                  customTrailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey.shade800),
                    onPressed: () => _confirmRemoveFavorite(collegeId),
                  ),
                  onFavoriteToggle: () {},
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
                      } catch (_) {}
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    if (!_markersLoaded) {
      return Center(child: CircularProgressIndicator());
    }

    final markers = _favorites.where((college) =>
      college["location.lat"] != null && college["location.lon"] != null
    ).map((college) {
      final id = college["id"].toString();
      final isSelected = _selectedCollegeId == id;

      return Marker(
        markerId: MarkerId(id),
        position: LatLng(college["location.lat"], college["location.lon"]),
        icon: isSelected ? _highlightMarker : _defaultMarker,
        zIndex: isSelected ? 2.0 : 1.0,
        onTap: () {
          setState(() => _selectedCollegeId = id);

          final index = _favorites.indexWhere((c) => c['id'].toString() == id);
          if (index != -1) {
            _scrollController.animateTo(
              index * 187.0,
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
        infoWindow: InfoWindow(
          title: college["school.name"],
          snippet: '${college["school.city"]}, ${college["school.state"]}',
          onTap: () async {
            final fullCollegeData = await CollegeService.fetchCollegeById(id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollegeDetailsScreen(college: fullCollegeData),
              ),
            );
          },
        ),
      );
    }).toSet();

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(39.8283, -98.5795),
        zoom: 4,
      ),
      markers: markers,
      onTap: (_) => setState(() => _selectedCollegeId = null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          "Please log in to view your saved colleges.",
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_favorites.isEmpty) return Center(child: Text("No favorites saved yet."));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  padding: EdgeInsets.all(12),
                  child: _buildMapListView(),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildMapView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
