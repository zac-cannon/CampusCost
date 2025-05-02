import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/college_tile.dart';
import '../services/college_service.dart';
import '../screens/college_details_screen.dart';

class MapListView extends StatefulWidget {
  final List<Map<String, dynamic>> colleges;
  final bool isMapView;
  final bool isFavoriteScreen;
  final void Function(String collegeId)? onRemoveFavorite;

  const MapListView({
    Key? key,
    required this.colleges,
    required this.isMapView,
    this.isFavoriteScreen = false,
    this.onRemoveFavorite,
  }) : super(key: key);

  @override
  State<MapListView> createState() => _MapListViewState();
}

class _MapListViewState extends State<MapListView> {
  String? _selectedCollegeId;
  GoogleMapController? _mapController;

  Widget _buildMapView() {
    final markers = widget.colleges.where((college) =>
      college["location.lat"] != null && college["location.lon"] != null
    ).map((college) {
      final id = college["id"].toString();
      return Marker(
        markerId: MarkerId(id),
        position: LatLng(college["location.lat"], college["location.lon"]),
        infoWindow: InfoWindow(
          title: college["school.name"],
          snippet: "${college["school.city"]}, ${college["school.state"]}",
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

  Widget _buildListView() {
    return ListView.builder(
      itemCount: widget.colleges.length,
      itemBuilder: (context, index) {
        final college = widget.colleges[index];
        final collegeId = college["id"].toString();
        return CollegeTile(
          college: college,
          isFavorite: true,
          isSelected: _selectedCollegeId == collegeId,
          onFavoriteToggle: () => widget.isFavoriteScreen && widget.onRemoveFavorite != null
              ? widget.onRemoveFavorite!(collegeId)
              : null,
          onTap: () async {
            setState(() => _selectedCollegeId = collegeId);
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMapView) {
      return _buildListView();
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMapView(),
            ),
          ),
        ),
      ],
    );
  }
} 
