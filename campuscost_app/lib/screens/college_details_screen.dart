import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'budget_planner_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/college_service.dart';

class CollegeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> college;

  const CollegeDetailsScreen({super.key, required this.college});
@override
  _CollegeDetailsScreenState createState() => _CollegeDetailsScreenState();
}

class _CollegeDetailsScreenState extends State<CollegeDetailsScreen> {
  bool isFavorite = false; // Track if the college is in favorites

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }
  void _checkFavoriteStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.college['id'].toString())
        .get();

    setState(() {
      isFavorite = doc.exists;
    });
  }
  void _toggleFavorite() async {
      final collegeId = widget.college['id'].toString();

      if (isFavorite) {
        await FavoriteService.removeFromFavorites(collegeId);
        setState(() {
          isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Removed from favorites")));
      } else {
        await FavoriteService.saveToFavorites(widget.college);
        setState(() {
          isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to favorites")));
      }
    }

  //Make sure URLs start with 'http://' otherwise the url launcher will not function.
  void _launchURL(String url) async {
    if (url.isNotEmpty) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://' + url;
      }
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double? graduationRate = widget.college["latest.completion.rate"] ??
        widget.college["latest.completion.rate.4yr"] ??
        widget.college["latest.completion.rate.2yr"] ??
        widget.college["latest.completion.rate_suppressed.four_year"] ??
        widget.college["latest.completion.rate_suppressed.consumer.overall_median"] ??
        widget.college["latest.completion.rate_suppressed_pell.four_year_150_pooled"] ??
        widget.college["latest.completion.rate_suppressed.overall"];

    double? retentionRate = widget.college["latest.student.retention_rate"] ??
        widget.college["latest.student.retention_rate.four_year.full_time"] ??
        widget.college["latest.student.retention_rate_suppressed.four_year.full_time_pooled"];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.college["school.name"] ?? "College Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.college["school.name"] ?? "Unknown College",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? const Color.fromARGB(255, 109, 109, 109) : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text("Location: ${widget.college["school.city"] ?? "N/A"}, ${widget.college["school.state"] ?? "N/A"}, ${widget.college["school.zip"] ?? "N/A"}"),
              GestureDetector(
                onTap: () => _launchURL(widget.college["school.school_url"] ?? ""),
                child: Text(
                  "Website: ${widget.college["school.school_url"] ?? "N/A"}",
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
              Text("In-State Tuition: \$${widget.college["latest.cost.tuition.in_state"] ?? "N/A"}"),
              Text("Out-of-State Tuition: \$${widget.college["latest.cost.tuition.out_of_state"] ?? "N/A"}"),
              Text("Admission Rate: ${(widget.college["latest.admissions.admission_rate.overall"] != null) ? (widget.college["latest.admissions.admission_rate.overall"] * 100).toStringAsFixed(2) + '%' : 'Data not available'}"),
              Text("Graduation Rate: ${graduationRate != null ? (graduationRate * 100).toStringAsFixed(2) + '%' : 'Not reported'}"),
              Text("Retention Rate: ${retentionRate != null ? (retentionRate * 100).toStringAsFixed(2) + '%' : 'Not reported'}"),
              Text("Median Earnings After 10 Years: \$${widget.college["latest.earnings.10_yrs_after_entry.median"] ?? "N/A"}"),
              Text("Students Receiving Pell Grants: ${(widget.college["latest.aid.pell_grant_rate"] != null) ? (widget.college["latest.aid.pell_grant_rate"] * 100).toStringAsFixed(2) + '%' : 'Data not available'}"),
              Text("Carnegie Classification: ${widget.college["school.carnegie_basic"] ?? "N/A"}"),
              Text("Accrediting Agency: ${widget.college["school.accreditor"] ?? "N/A"}"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetPlannerScreen(college: widget.college),
                    ),
                  );
                },
                child: Text("Plan a Budget for this College"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}