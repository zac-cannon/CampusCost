// updated_settings_screen.dart
import 'package:campuscost_app/screens/filters_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _maxNetCost = 100000;
  double _minNetCost = 0;
  bool _isPublic = true;
  bool _isPrivate = true;
  double _minAcceptanceRate = 0.0;
  double _maxAcceptanceRate = 1.0;
  String _selectedState = '';
  List<int> _selectedDegreeTypes = [1, 2, 3];
  String _defaultSort = 'tuition_low';
  bool _defaultMapView = true;
  bool _isLoaded = false;


  double _defaultScholarships = 0;
  double _defaultEfc = 0;
  double _defaultLoans = 0;
  double _defaultIncome = 0;
  double _defaultAdditional = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('preferences');

    final prefsDoc = await prefRef.doc('filters').get();
    final sortDoc = await prefRef.doc('display').get();
    final budgetDoc = await prefRef.doc('budget').get();

    if (prefsDoc.exists) {
      final prefs = prefsDoc.data()!;
      setState(() {
        _maxNetCost = (prefs['maxNetCost'] ?? 100000).toDouble();
        _minNetCost = (prefs['minNetCost'] ?? 0).toDouble();
        _isPublic = prefs['isPublic'] ?? true;
        _isPrivate = prefs['isPrivate'] ?? true;
        _minAcceptanceRate = (prefs['minAcceptanceRate'] ?? 0.0).toDouble();
        _maxAcceptanceRate = (prefs['maxAcceptanceRate'] ?? 1.0).toDouble();
        _selectedState = prefs['state'] ?? '';
        _selectedDegreeTypes = List<int>.from(prefs['degreeTypes'] ?? [1, 2, 3]);
      });
    }

    if (sortDoc.exists) {
      final sort = sortDoc.data()!;
      setState(() {
        _defaultSort = sort['sort'] ?? 'tuition_low';
        _defaultMapView = sort['mapView'] ?? true;
      });
    }

    if (budgetDoc.exists) {
      final b = budgetDoc.data()!;
      setState(() {
        _defaultScholarships = (b['scholarships'] ?? 0).toDouble();
        _defaultEfc = (b['efc'] ?? 0).toDouble();
        _defaultLoans = (b['loans'] ?? 0).toDouble();
        _defaultIncome = (b['income'] ?? 0).toDouble();
        _defaultAdditional = (b['additional'] ?? 0).toDouble();
      });
    }
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('preferences');

    await prefRef.doc('filters').set({
      'maxNetCost': _maxNetCost.toInt(),
      'minNetCost': _minNetCost.toInt(),
      'isPublic': _isPublic,
      'isPrivate': _isPrivate,
      'minAcceptanceRate': _minAcceptanceRate,
      'maxAcceptanceRate': _maxAcceptanceRate,
      'state': _selectedState,
      'degreeTypes': _selectedDegreeTypes,
    });

    await prefRef.doc('display').set({
      'sort': _defaultSort,
      'mapView': _defaultMapView,
    });

    await prefRef.doc('budget').set({
      'scholarships': _defaultScholarships,
      'efc': _defaultEfc,
      'loans': _defaultLoans,
      'income': _defaultIncome,
      'additional': _defaultAdditional,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Preferences saved")));
  }

  void _resetToDefault() {
    setState(() {
      _maxNetCost = 100000;
      _isPublic = true;
      _isPrivate = true;
      _minAcceptanceRate = 0.0;
      _selectedState = '';
      _selectedDegreeTypes = [1, 2, 3];
      _defaultSort = 'tuition_low';
      _defaultMapView = true;
      _defaultScholarships = 0;
      _defaultEfc = 0;
      _defaultLoans = 0;
      _defaultIncome = 0;
      _defaultAdditional = 0;
      _defaultScholarships = 0;
      _defaultEfc = 0;
      _defaultLoans = 0;
      _defaultIncome = 0;
      _defaultAdditional = 0;
    });
    _savePreferences();
  }

  Future<void> _openFiltersScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollegeFiltersScreen(
          initialMaxNetCost: _maxNetCost.toInt(),
          initialMinNetCost: _minNetCost.toInt(),
          initialIsPublic: _isPublic,
          initialIsPrivate: _isPrivate,
          initialMinAcceptanceRate: _minAcceptanceRate,
          initialMaxAcceptanceRate: _maxAcceptanceRate,
          initialState: _selectedState,
          initialDegreeTypes: _selectedDegreeTypes,
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _maxNetCost = result['maxNetCost'].toDouble();
        _minNetCost = result['minNetCost'].toDouble();
        _isPublic = result['isPublic'];
        _isPrivate = result['isPrivate'];
        _minAcceptanceRate = result['minAcceptanceRate'];
        _maxAcceptanceRate = result['maxAcceptanceRate'];
        _selectedState = result['state'];
        _selectedDegreeTypes = List<int>.from(result['degreeTypes']);
      });
      _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          "Please log in to view your preferences.",
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    if (!_isLoaded) {
    return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: _openFiltersScreen,
                icon: Icon(Icons.tune),
                label: Text("Edit Default Filters"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),

              Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Default Budget Inputs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      _buildNumberField("Scholarships & Grants", _defaultScholarships, (val) => _defaultScholarships = val),
                      _buildNumberField("Family Contribution", _defaultEfc, (val) => _defaultEfc = val),
                      _buildNumberField("Student Loans", _defaultLoans, (val) => _defaultLoans = val),
                      _buildNumberField("Student Income", _defaultIncome, (val) => _defaultIncome = val),
                      _buildNumberField("Additional Expenses", _defaultAdditional, (val) => _defaultAdditional = val),
                    ],
                  ),
                ),
              ),

              

             Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _savePreferences,
                  icon: Icon(Icons.save),
                  label: Text("Save"),
                ),
                ElevatedButton.icon(
                  onPressed: _resetToDefault,
                  icon: Icon(Icons.restore),
                  label: Text("Reset"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                ),
              ],
            ),


              SizedBox(height: 152),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signed out")));
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Sign Out"),
                    style: ElevatedButton.styleFrom(minimumSize: Size(150, 48)),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Delete Account"),
                          content: Text("Are you sure? This cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await user.delete();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account deleted")));
                      }
                    },
                    icon: Icon(Icons.delete_forever),
                    label: Text("Delete Account"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: Size(150, 48),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, double initialValue, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        initialValue: initialValue.toStringAsFixed(0),
        keyboardType: TextInputType.number,
        onChanged: (val) => onChanged(double.tryParse(val) ?? 0),
      ),
    );
  }
}
