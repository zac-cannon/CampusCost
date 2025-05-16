import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CollegeService {
  static const String baseUrl = "https://api.data.gov/ed/collegescorecard/v1/schools";
  static String get apiKey => dotenv.env['COLLEGE_SCORECARD_API_KEY'] ?? '';

  static const int maxPages = 200; // Fetch up to 20000 results
  static const int perPage = 100;

  //fetch colleges by name/state or pull all colleges
  static Future<List<dynamic>> fetchColleges({String collegeName = "", String state = ""}) async {
    final queryParts = [
      if (collegeName.isNotEmpty) "school.name=$collegeName",
      if (state.isNotEmpty) "school.state=$state",
    ];
    final query = queryParts.isNotEmpty ? "&${queryParts.join("&")}" : "";

    final List<dynamic> allColleges = [];

    for (int page = 0; page < maxPages; page++) {
      final url = Uri.parse(
        "$baseUrl?api_key=$apiKey&per_page=$perPage&page=$page$query"
        "&fields=id,school.name,latest.cost.tuition.in_state,latest.cost.tuition.out_of_state,school.ownership,school.iclevel,"
        "latest.cost.roomboard.oncampus,latest.admissions.admission_rate.overall,latest.student.size,school.city,school.state,"
        "school.zip,school.school_url,latest.completion.rate,latest.earnings.10_yrs_after_entry.median,"
        "latest.repayment.3_yr_repayment_rate,latest.aid.pell_grant_rate,school.carnegie_basic,school.accreditor,"
        "location.lat,location.lon,"
        "latest.cost.avg_net_price.overall,latest.cost.booksupply,"
        "latest.cost.other_expenses_oncampus,school.degrees_awarded.predominant,latest.student.retention_rate.overall.full_time,"
        "latest.aid.fed_loan_rate"
      );

      final response = await http.get(url);
      if (response.statusCode != 200) break;

      final data = json.decode(response.body);
      final results = data['results'] ?? [];

      if (results.isEmpty) break;
      allColleges.addAll(results);
    }

    return allColleges;
  }


  

//fetchCollege by ID
  static Future<Map<String, dynamic>> fetchCollegeById(String id) async {
  final url = Uri.parse(
    "$baseUrl?api_key=$apiKey&id=$id"
    "&fields=id,school.name,latest.cost.tuition.in_state,latest.cost.tuition.out_of_state,"
    "school.ownership,school.iclevel,latest.cost.roomboard.oncampus,"
    "latest.admissions.admission_rate.overall,latest.student.size,school.city,school.state,school.zip,"
    "school.school_url,latest.completion.rate,latest.earnings.10_yrs_after_entry.median,"
    "latest.repayment.3_yr_repayment_rate,latest.aid.pell_grant_rate,school.carnegie_basic,"
    "school.accreditor,location.lat,location.lon,latest.cost.avg_net_price.overall,"
    "latest.cost.booksupply,latest.cost.other_expenses_oncampus,school.degrees_awarded.predominant,"
    "latest.student.retention_rate.overall.full_time,latest.aid.fed_loan_rate"
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['results'][0];
  } else {
    throw Exception("Failed to fetch college by ID");
  }
}
static String getCurrentUserId() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }
  return user.uid;
}

  
}

class FavoriteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save college to favorites
  static Future<void> saveToFavorites(Map<String, dynamic> college) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final favoritesRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('favorites');

  // Count how many favorites currently exist
  final snapshot = await favoritesRef.get();
  final rank = snapshot.docs.length;

  final minimalData = {
    'id': college['id'],
    'school.name': college['school.name'],
    'school.city': college['school.city'],
    'school.state': college['school.state'],
    'location.lat': college['location.lat'],
    'location.lon': college['location.lon'],
    'rank': rank,
  };

  await favoritesRef.doc(college['id'].toString()).set(minimalData);
}


  // Remove from favorites
  static Future<void> removeFromFavorites(String collegeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    //Delete from favorites
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(collegeId)
        .delete();
    //Delete associated budget
    await _firestore
      .collection('users')
      .doc(uid)
      .collection('budgets')
      .doc(collegeId)
      .delete();
  }

  // Get all saved favorites
  static Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Save or update a budget for a specific college
  static Future<void> saveBudget(String collegeId, Map<String, dynamic> budget) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    print("📝 Saving budget for $collegeId: $budget");

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(collegeId)
        .set(budget);
  }


  // Fetch the budget for a specific college
  static Future<Map<String, dynamic>?> fetchBudget(String collegeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(collegeId)
        .get();

    return doc.exists ? doc.data() : null;
  }

  // Remove a budget (optional helper)
  static Future<void> removeBudget(String collegeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(collegeId)
        .delete();
  }

}


