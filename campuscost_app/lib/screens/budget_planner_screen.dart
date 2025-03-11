import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _prefillCollegeCosts();
  }

  void _prefillCollegeCosts() {
    if (widget.college != null) {
      setState(() {
        tuition = isInState
            ? widget.college!["latest.cost.tuition.out_of_state"]?.toDouble() ?? 0.0
            : widget.college!["latest.cost.tuition.in_state"]?.toDouble() ?? 0.0;
        housing = widget.college!["latest.cost.roomboard.oncampus"]?.toDouble() ?? 0.0;
        books = widget.college!["latest.cost.books_supplies"]?.toDouble() ?? 0.0;
        otherExpenses = widget.college!["latest.cost.other_expenses_oncampus"]?.toDouble() ?? 0.0;
        totalCost = tuition + housing + books + otherExpenses;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Budget Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.college?['school.name'] ?? 'Select a College',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
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
                Text("Estimated Costs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildLabeledText("Tuition", "\$${tuition.toStringAsFixed(2)}"),
                _buildLabeledText("Housing", housing > 0 ? "\$${housing.toStringAsFixed(2)}" : "N/A"),
                _buildLabeledText("Books & Supplies", books > 0 ? "\$${books.toStringAsFixed(2)}" : "N/A"),
                _buildLabeledText("Other Expenses", otherExpenses > 0 ? "\$${otherExpenses.toStringAsFixed(2)}" : "N/A"),
                _buildLabeledText("Additional Expenses", "\$${additionalExpenses.toStringAsFixed(2)}"),
                Divider(height: 30),
                Text("Financial Aid & Budget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                TextField(
                  controller: _scholarshipsController,
                  decoration: InputDecoration(labelText: "Scholarships & Grants", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _efcController,
                  decoration: InputDecoration(labelText: "Family Contribution", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _loansController,
                  decoration: InputDecoration(labelText: "Student Loans", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _additionalExpensesController,
                  decoration: InputDecoration(labelText: "Additional Expenses", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _calculateBudget,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      child: Text("Calculate Budget", style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: implement save budget functionality
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Budget Saved (placeholder)")));
                      },
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      child: Text("Save Budget", style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      child: Text("Cancel", style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 116, 0, 0))),
                    ),
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
        ),
      ),
    );
  }
}
