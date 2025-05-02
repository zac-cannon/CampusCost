import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/college_service.dart';
import 'college_details_screen.dart';

class SavedCollegesScreen extends StatefulWidget {
  @override
  _SavedCollegesScreenState createState() => _SavedCollegesScreenState();
}

class _SavedCollegesScreenState extends State<SavedCollegesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  bool _isMapView = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    final favorites = await FavoriteService.fetchFavorites();
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  void _removeFavorite(String collegeId) async {
    await FavoriteService.removeFromFavorites(collegeId);
    _loadFavorites();
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final college = _favorites[index];
        return Card(
          child: ListTile(
            title: Text(college["school.name"] ?? "Unknown"),
            subtitle: Text("${college["school.city"]}, ${college["school.state"]}"),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFavorite(college["id"].toString()),
            ),
            onTap: () async {
              final fullCollegeData = await CollegeService.fetchCollegeById(college["id"].toString());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CollegeDetailsScreen(college: fullCollegeData),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final markers = _favorites.where((college) =>
      college["location.lat"] != null && college["location.lon"] != null
    ).map((college) {
      return Marker(
        markerId: MarkerId(college["id"].toString()),
        position: LatLng(
          college["location.lat"],
          college["location.lon"],
        ),
        infoWindow: InfoWindow(
          title: college["school.name"],
          snippet: "${college["school.city"]}, ${college["school.state"]}",
          onTap: () async {
            final fullCollegeData = await CollegeService.fetchCollegeById(college["id"].toString());
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
        target: LatLng(39.8283, -98.5795), // Center of USA
        zoom: 4,
      ),
      markers: markers,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_favorites.isEmpty) return Center(child: Text("No favorites saved yet."));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list),
            Switch(
              value: _isMapView,
              onChanged: (value) {
                setState(() {
                  _isMapView = value;
                });
              },
            ),
            Icon(Icons.map),
          ],
        ),
        Expanded(
          child: _isMapView ? _buildMapView() : _buildListView(),
        ),
      ],
    );
  }
}
