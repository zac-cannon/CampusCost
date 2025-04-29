import 'package:campuscost_app/screens/home_screen.dart';
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

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 1; // Default to College Search

  final List<Widget> _pages = [
    HomeScreenTab(),
    CollegeSearchScreen(),
    SavedCollegesScreen(),
    Center(child: Text("Settings Coming Soon")),
  ];

  final List<String> _titles = [
    "Home",
    "College Search",
    "Saved Colleges",
    "Settings",
  ];

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: user != null
                    ? Row(
                        children: [
                          Text(user.email ?? "User"),
                          SizedBox(width: 10),
                          IconButton(
                            tooltip: "Logout",
                            icon: Icon(Icons.logout),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                          ),
                        ],
                      )
                    : TextButton(
                        onPressed: _openLogin,
                        child: Text("Login / Signup", style: TextStyle(color: Colors.white)),
                      ),
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Campus Cost', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            _buildDrawerItem(icon: Icons.home, label: 'Home', index: 0),
            _buildDrawerItem(icon: Icons.search, label: 'College Search', index: 1),
            _buildDrawerItem(icon: Icons.favorite, label: 'Saved Colleges', index: 2),
            _buildDrawerItem(icon: Icons.settings, label: 'Settings', index: 3),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String label, required int index}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _selectedIndex == index,
      onTap: () => _onItemSelected(index),
    );
  }
}