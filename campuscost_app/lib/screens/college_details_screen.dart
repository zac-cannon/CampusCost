import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_planner_screen.dart';
import '../services/college_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CollegeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> college;

  const CollegeDetailsScreen({super.key, required this.college});

  @override
  _CollegeDetailsScreenState createState() => _CollegeDetailsScreenState();
}

class _CollegeDetailsScreenState extends State<CollegeDetailsScreen> {
  bool isFavorite = false;

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
    final user = FirebaseAuth.instance.currentUser;


    if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You must be logged in to save favorites.")),
    );
    return; // Stop here if not logged in
  }

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

  void _launchURL(String url) async {
    if (url.isNotEmpty) {
      if (!url.startsWith('http')) {
        url = 'https://' + url;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(fontSize: 18),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    ),
  );
}


String formatMoney(dynamic value) {
  if (value is num) return "\$${value.toStringAsFixed(0)}";
  return "N/A";
}

String formatPercent(dynamic value) {
  if (value is num) return "${(value * 100).toStringAsFixed(1)}%";
  return "N/A";
}

String describeOwnership(dynamic code) {
  if(code == null) return "Not reported";
  switch (code) {
    case 1:
      return "Public";
    case 2:
      return "Private Nonprofit";
    case 3:
      return "Private For-Profit";
    default:
      return "Other / Unknown";
  }
}


String describeDegreeType(dynamic code) {
  switch (code) {
    case 1:
      return "Certificate School";
    case 2:
      return "2-Year College (Associates)";
    case 3:
      return "4-Year College (Bachelor's)";
    default:
      return "Not reported";
  }
}






Widget _buildCollegeDetails() {
  final college = widget.college;
  final name = college["school.name"] ?? "Unknown College";
  final location = "${college["school.city"] ?? "N/A"}, ${college["school.state"] ?? "N/A"}";
  final website = college["school.school_url"] ?? "";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.location_on_outlined, size: 20),
          SizedBox(width: 4),
          Text(location),
        ],
      ),
      SizedBox(height: 8),
      if (website.isNotEmpty)
        GestureDetector(
          onTap: () => _launchURL(website),
          child: Text(
            "Visit Website",
            style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
          ),
        ),
      SizedBox(height: 24),

      // Overview
      _section("🎓 Overview", [
        _infoRow("Average Net Cost", formatMoney(college["latest.cost.avg_net_price.overall"])),
        _infoRow("Admission Rate", formatPercent(college["latest.admissions.admission_rate.overall"])),
        _infoRow("Student Size", college["latest.student.size"]?.toString() ?? "N/A"),
        _infoRow("School Type", describeOwnership(college["school.ownership"])),
      ]),

      // Tuition & Costs
      _section("💰 Tuition & Costs", [
        _infoRow("In-State Tuition", formatMoney(college["latest.cost.tuition.in_state"])),
        _infoRow("Out-of-State Tuition", formatMoney(college["latest.cost.tuition.out_of_state"])),
        _infoRow("Room & Board", formatMoney(college["latest.cost.roomboard.oncampus"])),
        _infoRow("Books & Supplies", formatMoney(college["latest.cost.booksupply"])),
        _infoRow("Other Expenses", formatMoney(college["latest.cost.other_expenses_oncampus"])),
      ]),

      //Academics & Outcomes
      _section("📈 Academics & Outcomes", [
        _infoRow("Graduation Rate", formatPercent(college["latest.completion.rate_suppressed.overall"])),
        _infoRow("Retention Rate", formatPercent(college["latest.student.retention_rate.overall.full_time"])),
        _infoRow("Median Earnings (10 yrs)", formatMoney(college["latest.earnings.10_yrs_after_entry.median"])),
        _infoRow("Institution Level", describeDegreeType(college["school.degrees_awarded.predominant"])),


      ]),

      // Financial Aid
      _section("🎯 Financial Aid", [
        _infoRow("Pell Grant Recipients", formatPercent(college["latest.aid.pell_grant_rate"])),
        _infoRow("Undergrads Receiving Federal Loans", formatPercent(college["latest.aid.fed_loan_rate"])),
      ]),

      // Misc
      _section("🧩 Misc", [
        _infoRow("Accrediting Agency", college["school.accreditor"] ?? "N/A"),
        _infoRow("Carnegie Classification", college["school.carnegie_basic"]?.toString() ?? "N/A"),
      ]),

      SizedBox(height: 24),

      // Buttons
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: FavoriteService.fetchBudget(widget.college['id'].toString()),
            builder: (context, snapshot) {
              final hasBudget = snapshot.connectionState == ConnectionState.done && snapshot.data != null;

              return ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetPlannerScreen(college: widget.college),
                    ),
                  );
                },
                icon: Icon(Icons.attach_money),
                label: Text(hasBudget ? "View/Edit Budget" : "Plan Budget"),
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 16),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              );
            },
          ),


          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text("Back"),
            style: OutlinedButton.styleFrom(
              textStyle: TextStyle(fontSize: 16),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    final lat = widget.college["location.lat"];
    final lng = widget.college["location.lon"];
    final hasLocation = lat != null && lng != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.college["school.name"] ?? "College Details"),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color.fromARGB(255, 45, 45, 45) : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: College details
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
              child: _buildCollegeDetails(),
            ),
          ),

          // RIGHT: Google Map (dynamic location)
          Expanded(
            flex: 1,
            child: hasLocation
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId("college"),
                        position: LatLng(lat, lng),
                        infoWindow: InfoWindow(title: widget.college["school.name"]),
                      ),
                    },
                  )
                : Center(child: Text("Location not available")),
          ),

        ],
      ),
    );
  }
}
