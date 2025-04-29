import 'package:flutter/material.dart';

class CollegeFiltersScreen extends StatefulWidget {
  final int initialMaxTuition;
  final bool initialIsPublic;
  final bool initialIsPrivate;
  final double initialMinAcceptanceRate;
  final String initialState;
  final List<int> initialDegreeTypes;

  CollegeFiltersScreen({
    this.initialMaxTuition = 100000,
    this.initialIsPublic = true,
    this.initialIsPrivate = true,
    this.initialMinAcceptanceRate = 0.0,
    this.initialState = '',
    this.initialDegreeTypes = const [1, 2, 3],
  });

  @override
  _CollegeFiltersScreenState createState() => _CollegeFiltersScreenState();
}

class _CollegeFiltersScreenState extends State<CollegeFiltersScreen> {
  late double _tuitionRange;
  late bool _isPublic;
  late bool _isPrivate;
  late double _minAcceptanceRate;
  late String _selectedState;
  late List<int> _selectedDegreeTypes;

  final List<String> _usStates = [
    '', 'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA',
    'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
    'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX',
    'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  final Map<int, String> _degreeTypeLabels = {
    1: 'Certificate',
    2: '2-Year',
    3: '4-Year',
  };

  void _clearAllFilters() {
    setState(() {
      _tuitionRange = 100000;
      _isPublic = true;
      _isPrivate = true;
      _minAcceptanceRate = 0.0;
      _selectedState = '';
      _selectedDegreeTypes = [1, 2, 3];
    });
  }
  @override
  void initState() {
    super.initState();
    _tuitionRange = widget.initialMaxTuition.toDouble();
    _isPublic = widget.initialIsPublic;
    _isPrivate = widget.initialIsPrivate;
    _minAcceptanceRate = widget.initialMinAcceptanceRate;
    _selectedState = widget.initialState;
    _selectedDegreeTypes = List.from(widget.initialDegreeTypes);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Filters"),
        actions: [
          Tooltip(
            message: "Clear Filters",
            child: IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: _clearAllFilters,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
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
              onChanged: (value) => setState(() => _tuitionRange = value),
            ),

            SizedBox(height: 20),
            Text("College Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            CheckboxListTile(
              title: Text("Public Colleges"),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value ?? true),
            ),
            CheckboxListTile(
              title: Text("Private Colleges"),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value ?? true),
            ),

            SizedBox(height: 20),
            Text(
              "Min Acceptance Rate (${(_minAcceptanceRate * 100).toInt()}%)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _minAcceptanceRate,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: "${(_minAcceptanceRate * 100).toInt()}%",
              onChanged: (value) => setState(() => _minAcceptanceRate = value),
            ),

            SizedBox(height: 20),
            Text("Filter by State", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text("State: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: SizedBox(
                    width: 120,
                    child: DropdownButton<String>(
                      value: _selectedState.isEmpty ? null : _selectedState,
                      isExpanded: true,
                      items: _usStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state.isEmpty ? "Any" : state),
                        );
                      }).toList(),
                      hint: Text("Select"),
                      onChanged: (value) => setState(() => _selectedState = value ?? ''),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            Text("Institution Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ..._degreeTypeLabels.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.value),
                value: _selectedDegreeTypes.contains(entry.key),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedDegreeTypes.add(entry.key);
                    } else {
                      _selectedDegreeTypes.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),

            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'maxTuition': _tuitionRange.toInt(),
                    'isPublic': _isPublic,
                    'isPrivate': _isPrivate,
                    'minAcceptanceRate': _minAcceptanceRate,
                    'state': _selectedState,
                    'degreeTypes': _selectedDegreeTypes,
                  });
                },
                child: Text("Apply Filters"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
