import 'package:campuscost_app/screens/filters_screen.dart';
import 'package:flutter/material.dart';
import '../services/college_service.dart';
import 'college_details_screen.dart';

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
  bool _selectedIsPublic = true;
  bool _selectedIsPrivate = true;


  void _searchCollege() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await CollegeService.fetchColleges(_controller.text);
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
  Future<void> _toggleFavorite(Map<String, dynamic> college) async {
    final collegeId = college['id'].toString();

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter college name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
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
                SizedBox(
                  width: 20,
                ),
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
                          ),
                        ),
                      );

                      if (result != null && result is Map) {
                        _selectedMaxTuition = result['maxTuition'];
                        _selectedIsPublic = result['isPublic'];
                        _selectedIsPrivate = result['isPrivate'];

                        print("Selected Max Tuition: $_selectedMaxTuition");

                        setState(() {
                          _colleges = _colleges.where((college) {
                            final tuition = college["latest.cost.tuition.in_state"] ?? 0;
                            final ownership = college["school.ownership"];
                            final matchesTuition = tuition <= _selectedMaxTuition;
                            final matchesOwnership =
                                (_selectedIsPublic && ownership == 1) ||
                                (_selectedIsPrivate && (ownership == 2 || ownership == 3));
                            return matchesTuition && matchesOwnership;
                          }).toList();
                        });
                      }
                    },
                    child: Text("Filters"),
                  ),
                ),
              ],
            ),



            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _colleges.length,
                      itemBuilder: (context, index) {
                        final college = _colleges[index];
                        final collegeId = college['id'].toString();
                        final isFavorite = _favoriteIds.contains(collegeId);
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(college["school.name"] ?? "Unknown"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("In-State Tuition: \$${college["latest.cost.tuition.in_state"] ?? "N/A"}"),
                                Text("Out-of-State Tuition: \$${college["latest.cost.tuition.out_of_state"] ?? "N/A"}"),
                                Text("Admission Rate: ${((college["latest.admissions.admission_rate.overall"] ?? 0) * 100).toStringAsFixed(2)}%"),
                                Text("Student Size: ${college["latest.student.size"] ?? "N/A"}"),
                              ],
                            ),
                            trailing: IconButton( // Save icon button
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border, // button outline
                                color: isFavorite ? const Color.fromARGB(255, 109, 109, 109) : null,
                              ),
                              onPressed: () => _toggleFavorite(college), 
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CollegeDetailsScreen(college: college),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
