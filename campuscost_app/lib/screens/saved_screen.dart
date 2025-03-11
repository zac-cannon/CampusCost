import 'package:flutter/material.dart';
import '../services/college_service.dart';
import 'college_details_screen.dart';

class SavedCollegesScreen extends StatefulWidget {
  @override
  _SavedCollegesScreenState createState() => _SavedCollegesScreenState();
}

class _SavedCollegesScreenState extends State<SavedCollegesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_favorites.isEmpty) return Center(child: Text("No favorites saved yet."));

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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollegeDetailsScreen(college: college),
              ),
            ),
          ),
        );
      },
    );
  }
}
