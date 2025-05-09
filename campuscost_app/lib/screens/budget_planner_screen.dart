import 'package:campuscost_app/services/college_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetPlannerScreen extends StatefulWidget {
  final Map<String, dynamic>? college;
  const BudgetPlannerScreen({Key? key, this.college}) : super(key: key);

  @override
  _BudgetPlannerScreenState createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final TextEditingController _scholarshipsController = TextEditingController();
  final TextEditingController _efcController = TextEditingController();
  final TextEditingController _loansController = TextEditingController();
  final TextEditingController _additionalExpensesController = TextEditingController();
  final TextEditingController _studentIncomeController = TextEditingController();
  final TextEditingController _tuitionController = TextEditingController();
  final TextEditingController _housingController = TextEditingController();
  final TextEditingController _booksController = TextEditingController();
  final TextEditingController _manualAdditionalExpensesController = TextEditingController();



  double tuition = 0.0;
  double housing = 0.0;
  double books = 0.0;
  double additionalExpenses = 0.0;
  double totalCost = 0.0;
  double remainingCost = 0.0;
  double monthlyLoanPayment = 0.0;
  bool isInState = false;
  bool hasSavedBudget = false;

  @override
  void initState() {
    super.initState();
    _prefillCollegeCosts();
    loadSavedBudget().then((_) => loadDefaultsIfNeeded());

  }

  void _prefillCollegeCosts() {
    if (widget.college != null) {
      setState(() {
        tuition = isInState
            ? widget.college!["latest.cost.tuition.out_of_state"]?.toDouble() ?? 0.0
            : widget.college!["latest.cost.tuition.in_state"]?.toDouble() ?? 0.0;
        housing = widget.college!["latest.cost.roomboard.oncampus"]?.toDouble() ?? 0.0;
        books = widget.college!["latest.cost.booksupply"]?.toDouble() ?? 0.0;
        totalCost = tuition + housing + books + additionalExpenses;
      });
    }
  }
  Future<void> loadDefaultsIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.college == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('budget')
        .get();

    if (!hasSavedBudget && doc.exists) {
      final data = doc.data()!;
      setState(() {
        _scholarshipsController.text = (data['scholarships'] ?? 0).toString();
        _efcController.text = (data['efc'] ?? 0).toString();
        _loansController.text = (data['loans'] ?? 0).toString();
        _studentIncomeController.text = (data['income'] ?? 0).toString();
        _additionalExpensesController.text = (data['additional'] ?? 0).toString();
      });
    }
  }


  Future <void> loadSavedBudget() async {
    if (widget.college == null) return;
    final collegeId = widget.college!['id'].toString();
    final savedBudget = await FavoriteService.fetchBudget(collegeId);

    if (savedBudget != null) {
      setState(() {
        hasSavedBudget = true;
        tuition = (savedBudget['tuition'] ?? tuition).toDouble();
        housing = (savedBudget['housing'] ?? housing).toDouble();
        books = (savedBudget['books'] ?? books).toDouble();
        additionalExpenses = (savedBudget['additionalExpenses'] ?? additionalExpenses).toDouble();
        totalCost = (savedBudget['totalCost'] ?? totalCost).toDouble();
        remainingCost = (savedBudget['remainingCost'] ?? remainingCost).toDouble();
        monthlyLoanPayment = (savedBudget['monthlyLoanPayment'] ?? monthlyLoanPayment).toDouble();
        _scholarshipsController.text = (savedBudget['scholarships'] ?? 0.0).toString();
        _efcController.text = (savedBudget['efc'] ?? 0.0).toString();
        _loansController.text = (savedBudget['loans'] ?? 0.0).toString();
        _studentIncomeController.text = (savedBudget['studentIncome'] ?? 0.0).toString();

      });
    }
  }

  void _calculateBudget() {
    double scholarships = double.tryParse(_scholarshipsController.text) ?? 0.0;
    double efc = double.tryParse(_efcController.text) ?? 0.0;
    double loans = double.tryParse(_loansController.text) ?? 0.0;
    double studentIncome = double.tryParse(_studentIncomeController.text) ?? 0.0;
    additionalExpenses = double.tryParse(_additionalExpensesController.text) ?? 0.0;

    setState(() {
      totalCost = tuition + housing + books + additionalExpenses;
      remainingCost = (totalCost - (scholarships + efc + loans + studentIncome)).clamp(0, double.infinity);
      monthlyLoanPayment = ((loans * 4) / 120) * 1.05;
    });
  }

  void _toggleTuition(bool value) {
    setState(() {
      isInState = value;
      _prefillCollegeCosts();
    });
  }

  Widget _buildLabeledText(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            "$label:",
            style: TextStyle(
              fontSize: 16,               // Increased size
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,               // Match left label size
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _buildLabeledInput(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "$label:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}



  Widget _buildCostPieChart() {
    
  final sections = <PieChartSectionData>[
    PieChartSectionData(
      value: tuition * 4,
      title: 'Tuition',
      color: Colors.blueAccent,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    PieChartSectionData(
      value: housing * 4,
      title: 'Room & Board',
      color: Colors.green,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    PieChartSectionData(
      value: books * 4,
      title: 'Books',
      color: Colors.orange,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    PieChartSectionData(
      value: (additionalExpenses) * 4,
      title: 'Other',
      color: Colors.purple,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
    ),
  ];

  return PieChart(
    PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
      borderData: FlBorderData(show: false),
    ),
  );
}

Widget _buildPieChartLegend() {
  final items = [
    {'color': Colors.blueAccent, 'label': 'Tuition', 'value': tuition * 4},
    {'color': Colors.green, 'label': 'Room & Board', 'value': housing * 4},
    {'color': Colors.orange, 'label': 'Books', 'value': books * 4},
    {'color': Colors.purple, 'label': 'Other', 'value': (additionalExpenses) * 4},
  ];

  return Container(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  '${item['label']}: \$${(item['value'] as double).toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

void _showEditCostsDialog() {
  _tuitionController.text = tuition.toStringAsFixed(2);
  _housingController.text = housing.toStringAsFixed(2);
  _booksController.text = books.toStringAsFixed(2);
  _manualAdditionalExpensesController.text = additionalExpenses.toStringAsFixed(2);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Edit Prefilled Costs"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tuitionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Tuition"),
            ),
            TextField(
              controller: _housingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Room & Board"),
            ),
            TextField(
              controller: _booksController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Books & Supplies"),
            ),
            TextField(
              controller: _manualAdditionalExpensesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Additional Expenses"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            setState(() {
              tuition = double.tryParse(_tuitionController.text) ?? tuition;
              housing = double.tryParse(_housingController.text) ?? housing;
              books = double.tryParse(_booksController.text) ?? books;
              additionalExpenses = double.tryParse(_manualAdditionalExpensesController.text) ?? additionalExpenses;
              totalCost = tuition + housing + books + additionalExpenses;
            });
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    ),
  );
}






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Planner'),
        actions: [
          Tooltip(
            message: 'Clear Budget',
            child: IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () async {
                final collegeId = widget.college!['id'].toString();
                await FavoriteService.removeBudget(collegeId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Budget cleared")));
                setState(() {
                  _prefillCollegeCosts();
                  _scholarshipsController.clear();
                  _efcController.clear();
                  _loansController.clear();
                  _additionalExpensesController.clear();
                  totalCost = tuition + housing + books + additionalExpenses;
                  remainingCost = 0.0;
                  monthlyLoanPayment = 0.0;
                });
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.college?['school.name'] ?? 'Select a College', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Select Tuition Type:", style: TextStyle(fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              Text("In-State"),
                              Switch(value: isInState, onChanged: _toggleTuition),
                              Text("Out-of-State"),
                            ],
                          ),
                        ],
                      ),
                      Divider(height: 30),
                      Text("Estimated Annual Costs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 14),
                      _buildLabeledText("Tuition", "\$${tuition.toStringAsFixed(2)}"),
                      _buildLabeledText("Room & Board", housing > 0 ? "\$${housing.toStringAsFixed(2)}" : "N/A"),
                      _buildLabeledText("Books & Supplies", books > 0 ? "\$${books.toStringAsFixed(2)}" : "N/A"),
                      _buildLabeledText("Additional Expenses", "\$${additionalExpenses.toStringAsFixed(2)}"),

                      Divider(height: 30),
                      Text("Your Annual Financial Aid, Income, & Other Costs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 14),
                      _buildLabeledInput("Scholarships & Grants", _scholarshipsController),
                      SizedBox(height: 14),

                      _buildLabeledInput("Family Contribution", _efcController),
                      SizedBox(height: 14),
                      _buildLabeledInput("Student Income", _studentIncomeController),
                      SizedBox(height: 14),
                      _buildLabeledInput("Student Loans", _loansController),
                      SizedBox(height: 14),
                      _buildLabeledInput("Additional Expenses", _additionalExpensesController),

                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(onPressed: _calculateBudget, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: Text("Calculate Budget", style: TextStyle(fontSize: 16))),
                          ElevatedButton(onPressed: () async {
                            if (widget.college == null) return;
                            final collegeId = widget.college!['id'].toString();
                            await FavoriteService.saveToFavorites(widget.college!);
                            final budgetData = {
                            'tuition': tuition,
                            'housing': housing,
                            'books': books,
                            'additionalExpenses': additionalExpenses,
                            'scholarships': double.tryParse(_scholarshipsController.text) ?? 0.0,
                            'efc': double.tryParse(_efcController.text) ?? 0.0,
                            'studentIncome': double.tryParse(_studentIncomeController.text) ?? 0.0,
                            'loans': double.tryParse(_loansController.text) ?? 0.0,
                            'totalCost': totalCost,
                            'remainingCost': remainingCost,
                            'monthlyLoanPayment': monthlyLoanPayment,
                            'timestamp': FieldValue.serverTimestamp(),
                          };

                            await FavoriteService.saveBudget(collegeId, budgetData);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Budget saved")));
                          }, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: Text("Save Budget", style: TextStyle(fontSize: 16))),
                          ElevatedButton(
                            onPressed: _showEditCostsDialog,
                            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                            child: Text("Edit Costs", style: TextStyle(fontSize: 16)),
                          ),
                          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.white))),
                        ],

                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text("📊 4 year Cost Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 200, width: 200, child: _buildCostPieChart()),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(left: 20), // adjust amount as needed
                              child: _buildPieChartLegend(),
                            ),
                          ],
                        ),
                      ),
                      //SizedBox(height: 1),
                      Card(
                        margin: EdgeInsets.only(top: 24),
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Results", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              SizedBox(height: 12),
                              _buildLabeledText("Total Cost\n(Per Year)", "\$${totalCost.toStringAsFixed(2)}"),
                              _buildLabeledText("Total Cost\n(4 Years)", "\$${(totalCost * 4).toStringAsFixed(2)}"),
                              _buildLabeledText("Remaining Cost\n(Per Year)", remainingCost == 0 ? "Fully Covered" : "\$${remainingCost.toStringAsFixed(2)}"),
                              _buildLabeledText("Remaining Cost\n(4 Years)", remainingCost == 0 ? "Fully Covered" : "\$${(remainingCost * 4).toStringAsFixed(2)}"),
                              _buildLabeledText("Monthly Loan Payment", "\$${monthlyLoanPayment.toStringAsFixed(2)}"),
                              Text("(Based on 10-year term at ~5% interest)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),




                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
