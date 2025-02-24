import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finance Tracker')),
      body: Center(child: Text('Welcome to Your Finance App!')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to 
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
