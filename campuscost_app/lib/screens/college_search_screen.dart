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
  bool _isLoading = false;

  void _searchCollege() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await CollegeService.fetchColleges(_controller.text);
      setState(() {
        _colleges = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data. Please try again.")));
    }

    setState(() {
      _isLoading = false;
    });
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
            ElevatedButton(onPressed: _searchCollege, child: Text("Search")),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _colleges.length,
                      itemBuilder: (context, index) {
                        final college = _colleges[index];
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
