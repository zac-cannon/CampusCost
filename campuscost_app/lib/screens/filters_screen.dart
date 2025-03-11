import 'package:flutter/material.dart';

class CollegeFiltersScreen extends StatefulWidget {
  @override
  _CollegeFiltersScreenState createState() => _CollegeFiltersScreenState();
}

class _CollegeFiltersScreenState extends State<CollegeFiltersScreen> {
  double _tuitionRange = 100000; // Default max tuition filter
  bool _isPublic = true;
  bool _isPrivate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Filters")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Max Tuition Price (\$${_tuitionRange.toInt()})",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _tuitionRange,
              min: 0,
              max: 100000,
              divisions: 100,
              label: _tuitionRange.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _tuitionRange = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              "College Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            CheckboxListTile(
              title: Text("Public Colleges"),
              value: _isPublic,
              onChanged: (value) {
                setState(() => _isPublic = value ?? true);
              },
            ),
            CheckboxListTile(
              title: Text("Private Colleges"),
              value: _isPrivate,
              onChanged: (value) {
                setState(() => _isPrivate = value ?? true);
              },
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'maxTuition': _tuitionRange.toInt(),
                    'isPublic': _isPublic,
                    'isPrivate': _isPrivate,
                  });
                },
                child: Text("Apply Filters"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
