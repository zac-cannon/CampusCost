import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      title: 'Finance Tracker App',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _getCounterValue();
  }

  Future<void> _getCounterValue() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('example')
        .doc('counter')
        .get();
    if (snapshot.exists) {
      setState(() {
        _counter = snapshot['counter-num'];
      });
    }
  }

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });
    await FirebaseFirestore.instance
        .collection('example')
        .doc('counter')
        .update({'counter-num': _counter});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Tracker App'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Home Dashboard'),
            Tab(text: 'Income/Expenses'),
            Tab(text: 'Category'),
            Tab(text: 'Budget Planner'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeTab(counter: _counter, incrementCounter: _incrementCounter),
          IncomeExpensesTab(),
          CategoryTab(),
          BudgetPlannerTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final int counter;
  final VoidCallback incrementCounter;

  HomeTab({required this.counter, required this.incrementCounter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('You have pushed the button this many times:'),
          Text(
            '$counter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          FloatingActionButton(
            onPressed: incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class IncomeExpensesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Income/Expenses'));
  }
}

class CategoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Category'));
  }
}

class BudgetPlannerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Budget Planner'));
  }
}

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Settings'));
  }
}