import 'package:campuscost_app/screens/saved_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/college_search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Cost',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Ensuring background color contrasts with navbar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue, // Navbar distinct color
          foregroundColor: Colors.white, // Text and icon colors for contrast
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campus Cost'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Home'),
            Tab(text: 'College Search'),
            Tab(text: 'Saved Colleges/Budgets'),
            Tab(text: 'Settings'),
          ],
          labelPadding: EdgeInsets.zero,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelColor: Colors.white,
        ),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeTab(),
          CollegeSearchTab(),
          BudgetPlannerTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to the Campus Cost: College Cost & Budget Planner!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          user != null
              ? Column(
                  children: [
                    Text("Logged in as: ${user.email}"),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Logged out")),
                        );
                      },
                      child: Text("Logout"),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                  child: Text("Login / Sign Up"),
                ),
        ],
      ),
    );
  }
}

class CollegeSearchTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CollegeSearchScreen(); // Embed it directly inside the tab
  }
}

class BudgetPlannerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SavedCollegesScreen();
  }
}

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Settings'));
  }
}