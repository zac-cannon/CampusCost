import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSearchTabRequested;
  const HomeScreen({super.key, required this.onSearchTabRequested});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 80, color: Theme.of(context).primaryColor),
              SizedBox(height: 24),
              Text(
                'Welcome to Campus Cost: The College Comparison & Budget Planner Tool!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              if (user == null) ...[
                Text(
                  'Login or create an account to save colleges, plan budgets, and make informed decisions about your future.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'Welcome back, ${user.email ?? "Student"}!',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text('📌 Saved Colleges: Loading...', style: TextStyle(fontSize: 16)),
                      Text('💰 Budgets Created: Coming soon...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 40),
              ElevatedButton.icon(
                icon: Icon(Icons.search),
                label: Text('Start Searching Colleges'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onSearchTabRequested,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
