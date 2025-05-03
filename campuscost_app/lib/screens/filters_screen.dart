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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 900),
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSection(title: "\uD83C\uDF93 Maximum Net Cost", child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("\$${_tuitionRange.toInt()}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Slider(
                        value: _tuitionRange,
                        min: 0,
                        max: 100000,
                        divisions: 100,
                        label: _tuitionRange.toInt().toString(),
                        onChanged: (value) => setState(() => _tuitionRange = value),
                      ),
                    ],
                  )),

                  _buildSection(title: "\uD83C\uDFEB College Type", child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text("Public"),
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value ?? true),
                      ),
                      CheckboxListTile(
                        title: Text("Private"),
                        value: _isPrivate,
                        onChanged: (value) => setState(() => _isPrivate = value ?? true),
                      ),
                    ],
                  )),

                  _buildSection(title: "\uD83D\uDCCD Location", child: Row(
                    children: [
                      Icon(Icons.location_on_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(border: InputBorder.none, hintText: "Select State"),
                          value: _selectedState.isEmpty ? null : _selectedState,
                          items: _usStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state.isEmpty ? "Any" : state),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedState = value ?? ''),
                        ),
                      ),
                    ],
                  )),

                  _buildSection(title: "\u2705 Min Acceptance Rate", child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${(_minAcceptanceRate * 100).toInt()}%",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Slider(
                        value: _minAcceptanceRate,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: "${(_minAcceptanceRate * 100).toInt()}%",
                        onChanged: (value) => setState(() => _minAcceptanceRate = value),
                      ),
                    ],
                  )),

                  _buildSection(title: "\uD83D\uDCDA Degree Type", child: Column(
                    children: _degreeTypeLabels.entries.map((entry) {
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
                  )),

                  SizedBox(height: 100),
                ],
              ),

              Positioned(
                bottom: 20,
                left: 300,
                right: 300,
                child: ElevatedButton.icon(
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
                  icon: Icon(Icons.filter_alt),
                  label: Text("Apply Filters", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
