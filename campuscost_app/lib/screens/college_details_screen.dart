import 'package:flutter/material.dart';
import 'budget_planner_screen.dart';

class CollegeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> college;

  const CollegeDetailsScreen({super.key, required this.college});

  @override
  Widget build(BuildContext context) {
    double? graduationRate = college["latest.completion.rate"] ??
        college["latest.completion.rate.4yr"] ??
        college["latest.completion.rate.2yr"] ??
        college["latest.completion.rate_suppressed.four_year"] ??
        college["latest.completion.rate_suppressed.consumer.overall_median"] ??
        college["latest.completion.rate_suppressed_pell.four_year_150_pooled"] ??
        college["latest.completion.rate_suppressed.overall"];

    double? retentionRate = college["latest.student.retention_rate"] ??
        college["latest.student.retention_rate.four_year.full_time"] ??
        college["latest.student.retention_rate_suppressed.four_year.full_time_pooled"];

    return Scaffold(
      appBar: AppBar(
        title: Text(college["school.name"] ?? "College Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                college["school.name"] ?? "Unknown College",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text("Location: ${college["school.city"] ?? "N/A"}, ${college["school.state"] ?? "N/A"}, ${college["school.zip"] ?? "N/A"}"),
              Text("Website: ${college["school.school_url"] ?? "N/A"}"),
              Text("In-State Tuition: \$${college["latest.cost.tuition.in_state"] ?? "N/A"}"),
              Text("Out-of-State Tuition: \$${college["latest.cost.tuition.out_of_state"] ?? "N/A"}"),
              Text("Admission Rate: ${(college["latest.admissions.admission_rate.overall"] != null) ? (college["latest.admissions.admission_rate.overall"] * 100).toStringAsFixed(2) + '%' : 'Data not available'}"),
              Text("Graduation Rate: ${graduationRate != null ? (graduationRate * 100).toStringAsFixed(2) + '%' : 'Not reported'}"),
              Text("Retention Rate: ${retentionRate != null ? (retentionRate * 100).toStringAsFixed(2) + '%' : 'Not reported'}"),
              Text("Median Earnings After 10 Years: \$${college["latest.earnings.10_yrs_after_entry.median"] ?? "N/A"}"),
              Text("Student Loan Repayment Rate: ${(college["latest.repayment.3_yr_repayment_rate"] != null) ? (college["latest.repayment.3_yr_repayment_rate"] * 100).toStringAsFixed(2) + '%' : 'Data not available'}"),
              Text("Students Receiving Pell Grants: ${(college["latest.aid.pell_grant_rate"] != null) ? (college["latest.aid.pell_grant_rate"] * 100).toStringAsFixed(2) + '%' : 'Data not available'}"),
              Text("Carnegie Classification: ${college["school.carnegie_basic"] ?? "N/A"}"),
              Text("Accrediting Agency: ${college["school.accreditor"] ?? "N/A"}"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetPlannerScreen(college: college),
                    ),
                  );
                },
                child: Text("Plan Budget for this College"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  
                },
                child: Text("Save this college"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
