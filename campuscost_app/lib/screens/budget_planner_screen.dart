import 'package:campuscost_app/services/college_service.dart';
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

  double tuition = 0.0;
  double housing = 0.0;
  double books = 0.0;
  double otherExpenses = 0.0;
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
    loadSavedBudget();
  }

  void _prefillCollegeCosts() {
    if (widget.college != null) {
      setState(() {
        tuition = isInState
            ? widget.college!["latest.cost.tuition.out_of_state"]?.toDouble() ?? 0.0
            : widget.college!["latest.cost.tuition.in_state"]?.toDouble() ?? 0.0;
        housing = widget.college!["latest.cost.roomboard.oncampus"]?.toDouble() ?? 0.0;
        books = widget.college!["latest.cost.booksupply"]?.toDouble() ?? 0.0;
        otherExpenses = widget.college!["latest.cost.other_expenses_oncampus"]?.toDouble() ?? 0.0;
        totalCost = tuition + housing + books + otherExpenses;
      });
    }
  }

  void loadSavedBudget() async {
    if (widget.college == null) return;
    final collegeId = widget.college!['id'].toString();
    final savedBudget = await FavoriteService.fetchBudget(collegeId);

    if (savedBudget != null) {
      setState(() {
        hasSavedBudget = true;
        tuition = (savedBudget['tuition'] ?? tuition).toDouble();
        housing = (savedBudget['housing'] ?? housing).toDouble();
        books = (savedBudget['books'] ?? books).toDouble();
        otherExpenses = (savedBudget['otherExpenses'] ?? otherExpenses).toDouble();
        additionalExpenses = (savedBudget['additionalExpenses'] ?? additionalExpenses).toDouble();
        totalCost = (savedBudget['totalCost'] ?? totalCost).toDouble();
        remainingCost = (savedBudget['remainingCost'] ?? remainingCost).toDouble();
        monthlyLoanPayment = (savedBudget['monthlyLoanPayment'] ?? monthlyLoanPayment).toDouble();
      });
    }
  }

  void _calculateBudget() {
    double scholarships = double.tryParse(_scholarshipsController.text) ?? 0.0;
    double efc = double.tryParse(_efcController.text) ?? 0.0;
    double loans = double.tryParse(_loansController.text) ?? 0.0;
    additionalExpenses = double.tryParse(_additionalExpensesController.text) ?? 0.0;

    setState(() {
      totalCost = tuition + housing + books + otherExpenses + additionalExpenses;
      remainingCost = totalCost - (scholarships + efc + loans);
      monthlyLoanPayment = (loans / 120) * 1.05;
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
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(flex: 2, child: Text("$label:", style: TextStyle(fontWeight: FontWeight.w600))),
          Flexible(flex: 3, child: Text(value, textAlign: TextAlign.right)),
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
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    PieChartSectionData(
      value: housing * 4,
      title: 'Housing',
      color: Colors.green,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    PieChartSectionData(
      value: books * 4,
      title: 'Books',
      color: Colors.orange,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    PieChartSectionData(
      value: otherExpenses * 4,
      title: 'Other',
      color: Colors.purple,
      radius: 60,
      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    if (additionalExpenses > 0)
      PieChartSectionData(
        value: additionalExpenses * 4,
        title: 'Extra',
        color: Colors.redAccent,
        radius: 60,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                  totalCost = tuition + housing + books + otherExpenses;
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
                      _buildLabeledText("Tuition", "\$${tuition.toStringAsFixed(2)}"),
                      _buildLabeledText("Housing", housing > 0 ? "\$${housing.toStringAsFixed(2)}" : "N/A"),
                      _buildLabeledText("Books & Supplies", books > 0 ? "\$${books.toStringAsFixed(2)}" : "N/A"),
                      _buildLabeledText("Other Expenses", otherExpenses > 0 ? "\$${otherExpenses.toStringAsFixed(2)}" : "N/A"),
                      _buildLabeledText("Additional Expenses", "\$${additionalExpenses.toStringAsFixed(2)}"),
                      Divider(height: 30),
                      Text("Financial Aid & Budget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      TextField(controller: _scholarshipsController, decoration: InputDecoration(labelText: "Scholarships & Grants", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                      SizedBox(height: 12),
                      TextField(controller: _efcController, decoration: InputDecoration(labelText: "Family Contribution", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                      SizedBox(height: 12),
                      TextField(controller: _loansController, decoration: InputDecoration(labelText: "Student Loans", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                      SizedBox(height: 12),
                      TextField(controller: _additionalExpensesController, decoration: InputDecoration(labelText: "Additional Expenses", border: OutlineInputBorder()), keyboardType: TextInputType.number),
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
                              'otherExpenses': otherExpenses,
                              'additionalExpenses': additionalExpenses,
                              'totalCost': totalCost,
                              'remainingCost': remainingCost,
                              'monthlyLoanPayment': monthlyLoanPayment,
                              'timestamp': FieldValue.serverTimestamp(),
                            };
                            await FavoriteService.saveBudget(collegeId, budgetData);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Budget saved")));
                          }, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: Text("Save Budget", style: TextStyle(fontSize: 16))),
                          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.white))),
                        ],
                      ),
                      Divider(height: 36),
                      Text("Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildLabeledText("Total Cost", "\$${totalCost.toStringAsFixed(2)}"),
                      _buildLabeledText("Remaining Cost", "\$${remainingCost.toStringAsFixed(2)}"),
                      _buildLabeledText("Monthly Loan Payment", "\$${monthlyLoanPayment.toStringAsFixed(2)}"),
                      Text("(Based on 10-year term at ~5% interest)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text("📊 Cost Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      SizedBox(height: 280, child: _buildCostPieChart()),
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
