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
  final TextEditingController _livingExpensesController = TextEditingController();

  double tuition = 0.0;
  double housing = 12000.0; // Estimated default
  double books = 1200.0;
  double otherExpenses = 5000.0;
  double livingExpenses = 0.0;
  double totalCost = 0.0;
  double remainingCost = 0.0;
  double monthlyLoanPayment = 0.0;
  bool isInState = true;

  @override
  void initState() {
    super.initState();
    _prefillCollegeCosts();
  }

  void _prefillCollegeCosts() {
    if (widget.college != null) {
      setState(() {
        tuition = isInState
            ? widget.college!["latest.cost.tuition.in_state"]?.toDouble() ?? 0.0
            : widget.college!["latest.cost.tuition.out_of_state"]?.toDouble() ?? 0.0;
        totalCost = tuition + housing + books + otherExpenses;
      });
    }
  }

  void _calculateBudget() {
    double scholarships = double.tryParse(_scholarshipsController.text) ?? 0.0;
    double efc = double.tryParse(_efcController.text) ?? 0.0;
    double loans = double.tryParse(_loansController.text) ?? 0.0;
    livingExpenses = double.tryParse(_livingExpensesController.text) ?? 0.0;

    setState(() {
      totalCost = tuition + housing + books + otherExpenses + livingExpenses;
      remainingCost = totalCost - (scholarships + efc + loans);
      monthlyLoanPayment = (loans / 120) * 1.05; // Approx. 10-year repayment at 5% interest
    });
  }

  void _toggleTuition(bool value) {
    setState(() {
      isInState = value;
      _prefillCollegeCosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Budget Planner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.college?["school.name"] ?? "Select a College",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Select Tuition Type:"),
                Row(
                  children: [
                    Text("In-State"),
                    Switch(value: isInState, onChanged: _toggleTuition),
                    Text("Out-of-State"),
                  ],
                ),
              ],
            ),
            Divider(),
            Text("Estimated Costs:"),
            Text("Tuition: \$${tuition.toStringAsFixed(2)}"),
            Text("Housing: \$${housing.toStringAsFixed(2)}"),
            Text("Books & Supplies: \$${books.toStringAsFixed(2)}"),
            Text("Other Expenses: \$${otherExpenses.toStringAsFixed(2)}"),
            Text("Living Expenses: \$${livingExpenses.toStringAsFixed(2)}"),
            Divider(),
            Text("Financial Aid & Budget:"),
            TextField(controller: _scholarshipsController, decoration: InputDecoration(labelText: "Scholarships & Grants"), keyboardType: TextInputType.number),
            TextField(controller: _efcController, decoration: InputDecoration(labelText: "Expected Family Contribution (EFC)"), keyboardType: TextInputType.number),
            TextField(controller: _loansController, decoration: InputDecoration(labelText: "Student Loans"), keyboardType: TextInputType.number),
            TextField(controller: _livingExpensesController, decoration: InputDecoration(labelText: "Living Expenses"), keyboardType: TextInputType.number),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _calculateBudget, child: Text("Calculate Budget")),
            Divider(),
            Text("Total Cost: \$${totalCost.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Remaining Cost: \$${remainingCost.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Estimated Monthly Loan Payment: \$${monthlyLoanPayment.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}