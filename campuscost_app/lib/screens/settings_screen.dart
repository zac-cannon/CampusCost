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
  bool _isPublic = true;
  bool _isPrivate = true;
  double _minAcceptanceRate = 0.0;
  String _selectedState = '';
  List<int> _selectedDegreeTypes = [1, 2, 3];
  String _defaultSort = 'tuition_low';

  double _monthlyBudget = 0;
  double _maxLoanAmount = 0;
  double _targetLoanPayment = 0;

  final List<String> _sortOptions = [
    'tuition_low',
    'acceptance_high',
    'student_size_large'
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('filters')
        .get();

    final sortDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('display')
        .get();

    final budgetDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('budget')
        .get();

    if (prefsDoc.exists) {
      final prefs = prefsDoc.data()!;
      setState(() {
        _maxNetCost = (prefs['maxNetCost'] ?? 100000).toDouble();
        _isPublic = prefs['isPublic'] ?? true;
        _isPrivate = prefs['isPrivate'] ?? true;
        _minAcceptanceRate = (prefs['minAcceptanceRate'] ?? 0.0).toDouble();
        _selectedState = prefs['state'] ?? '';
        _selectedDegreeTypes = List<int>.from(prefs['degreeTypes'] ?? [1, 2, 3]);
      });
    }

    if (sortDoc.exists) {
      _defaultSort = sortDoc.data()!['sort'] ?? 'tuition_low';
    }

    if (budgetDoc.exists) {
      final b = budgetDoc.data()!;
      setState(() {
        _monthlyBudget = (b['monthlyBudget'] ?? 0).toDouble();
        _maxLoanAmount = (b['maxLoan'] ?? 0).toDouble();
        _targetLoanPayment = (b['targetLoanPayment'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences');

    await prefRef.doc('filters').set({
      'maxNetCost': _maxNetCost.toInt(),
      'isPublic': _isPublic,
      'isPrivate': _isPrivate,
      'minAcceptanceRate': _minAcceptanceRate,
      'state': _selectedState,
      'degreeTypes': _selectedDegreeTypes,
    });

    await prefRef.doc('display').set({
      'sort': _defaultSort
    });

    await prefRef.doc('budget').set({
      'monthlyBudget': _monthlyBudget,
      'maxLoan': _maxLoanAmount,
      'targetLoanPayment': _targetLoanPayment,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Preferences saved")),
    );
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
      _monthlyBudget = 0;
      _maxLoanAmount = 0;
      _targetLoanPayment = 0;
    });
    _savePreferences();
  }

  Future<void> _openFiltersScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollegeFiltersScreen(
          initialMaxTuition: _maxNetCost.toInt(),
          initialIsPublic: _isPublic,
          initialIsPrivate: _isPrivate,
          initialMinAcceptanceRate: _minAcceptanceRate,
          initialState: _selectedState,
          initialDegreeTypes: _selectedDegreeTypes,
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _maxNetCost = result['maxTuition'].toDouble();
        _isPublic = result['isPublic'];
        _isPrivate = result['isPrivate'];
        _minAcceptanceRate = result['minAcceptanceRate'];
        _selectedState = result['state'];
        _selectedDegreeTypes = List<int>.from(result['degreeTypes']);
      });
      _savePreferences();
    }
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onPressed, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("User: ${user?.email ?? 'Not signed in'}"),
              SizedBox(height: 24),

              Text("Default Sort Option"),
              DropdownButton<String>(
                value: _defaultSort,
                onChanged: (value) => setState(() => _defaultSort = value!),
                items: [
                  DropdownMenuItem(value: 'tuition_low', child: Text("Tuition: Low to High")),
                  DropdownMenuItem(value: 'acceptance_high', child: Text("Acceptance Rate: High to Low")),
                  DropdownMenuItem(value: 'student_size_large', child: Text("Student Size: Largest First")),
                ],
              ),

              SizedBox(height: 24),
              Text("Budgeting Preferences", style: Theme.of(context).textTheme.titleMedium),

              TextField(
                decoration: InputDecoration(labelText: "Monthly Budget (est.)"),
                keyboardType: TextInputType.number,
                onChanged: (value) => _monthlyBudget = double.tryParse(value) ?? 0,
                controller: TextEditingController(text: _monthlyBudget.toStringAsFixed(0)),
              ),
              /*TextField(
                decoration: InputDecoration(labelText: "Max Willing Loan Amount"),
                keyboardType: TextInputType.number,
                onChanged: (value) => _maxLoanAmount = double.tryParse(value) ?? 0,
                controller: TextEditingController(text: _maxLoanAmount.toStringAsFixed(0)),
              ),
              TextField(
                decoration: InputDecoration(labelText: "Target Monthly Loan Payment"),
                keyboardType: TextInputType.number,
                onChanged: (value) => _targetLoanPayment = double.tryParse(value) ?? 0,
                controller: TextEditingController(text: _targetLoanPayment.toStringAsFixed(0)),
              ),*/

              SizedBox(height: 24),
              _buildActionButton(icon: Icons.tune, label: "Edit Search Filters", onPressed: _openFiltersScreen),
              _buildActionButton(icon: Icons.save, label: "Save Preferences", onPressed: _savePreferences),
              _buildActionButton(icon: Icons.restore, label: "Reset to Default", onPressed: _resetToDefault, color: Colors.grey.shade700),
              SizedBox(height: 32),

              if (user != null) ...[
                _buildActionButton(icon: Icons.logout, label: "Sign Out", onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signed out")));
                }),
                _buildActionButton(icon: Icons.delete_forever, label: "Delete Account", onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Delete Account"),
                      content: Text("Are you sure? This cannot be undone."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await user.delete();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account deleted")));
                  }
                }, color: Colors.red.shade700),
              ],
            ],
          ),
        ),
      ),
    );
  }
}