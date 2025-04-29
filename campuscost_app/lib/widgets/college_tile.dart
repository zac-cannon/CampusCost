// lib/widgets/college_tile.dart
import 'package:campuscost_app/screens/budget_planner_screen.dart';
import 'package:flutter/material.dart';
import '../screens/college_details_screen.dart';

class CollegeTile extends StatelessWidget {
  final Map<String, dynamic> college;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final bool isSelected;

  const CollegeTile({
    Key? key,
    required this.college,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  String formatMoney(dynamic value) {
    if (value is num) return "\$${value.toStringAsFixed(0)}";
    return "N/A";
  }

  String formatPercent(dynamic value) {
    if (value is num) return "${(value * 100).toStringAsFixed(1)}%";
    return "N/A";
  }

  String describeOwnership(dynamic code) {
    switch (code) {
      case 1:
        return "Public";
      case 2:
        return "Private Nonprofit";
      case 3:
        return "Private For-Profit";
      default:
        return "Other";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        title: Text(
          college["school.name"] ?? "Unknown",
          maxLines: 2,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Avg. Net Cost: ${formatMoney(college["latest.cost.avg_net_price.overall"])}"),
              Text("Admission Rate: ${formatPercent(college["latest.admissions.admission_rate.overall"])}"),
              Text("Student Size: ${college["latest.student.size"]?.toString() ?? "N/A"}"),
              Text("School Type: ${describeOwnership(college["school.ownership"])}"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollegeDetailsScreen(college: college),
                          ),
                        );
                      },
                      icon: Icon(Icons.arrow_forward, size: 16),
                      label: Text("View Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 103, 159, 254),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetPlannerScreen(college: college),
                    ),
                  );
                      },
                      icon: Icon(Icons.attach_money, size: 18),
                      label: Text("Plan Budget"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.grey.shade800,
          ),
          onPressed: onFavoriteToggle,
        ),
      ),
    );
  }
}
