import 'package:campuscost_app/screens/home_screen.dart';
import 'package:campuscost_app/screens/saved_screen.dart';
import 'package:campuscost_app/screens/settings_screen.dart';
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
        useMaterial3: false,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1976D2),
          secondary: Color(0xFF42A5F5),
          background: Color(0xFFF7F9FC),
          surface: Colors.white,
          error: Color(0xFFD32F2F),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: Color(0xFFF7F9FC),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      
      home: AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Widget> get _pages => [
  HomeScreen(onSearchTabRequested: () {
    _tabController.animateTo(1);
  }),
  CollegeSearchScreen(),
  SavedCollegesScreen(),
  SettingsScreen(),
];

  final List<Tab> _tabs = [
  Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.home),
        SizedBox(width: 8),
        Text("Home"),
      ],
    ),
  ),
  Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search),
        SizedBox(width: 8),
        Text("Search"),
      ],
    ),
  ),
  Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite),
        SizedBox(width: 8),
        Text("Saved Colleges"),
      ],
    ),
  ),
  Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.settings),
        SizedBox(width: 8),
        Text("User Preferences"),
      ],
    ),
  ),
];


  @override
void initState() {
  super.initState();
  _tabController = TabController(length: _tabs.length, vsync: this);

  //Force a rebuild when tab animation completes to fix indicator glitch
  _tabController.animation?.addListener(() {
    setState(() {});
  });
}


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Text("Campus Cost", style: TextStyle(fontSize: 20)),
            SizedBox(width: 24),
            Expanded(
              child:TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3, // thin underline
                labelPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _tabs,
              )


            ),
            SizedBox(width: 16),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;

                if (user != null) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.email ?? "", style: TextStyle(fontSize: 14, color: Colors.white)),
                      SizedBox(width: 8),
                      IconButton(
                        tooltip: "Logout",
                        icon: Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Logged out")));
                        },
                      ),
                    ],
                  );
                } else {
                  return TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    child: Text("Login / Signup", style: TextStyle(color: Colors.white)),
                  );
                }
              },
            ),

          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: TabBarView(
        controller: _tabController,
        children: _pages,
      ),
    );
  }
}
