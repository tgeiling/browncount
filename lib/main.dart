// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'provider.dart';
import 'start.dart';
import 'stats.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider()..loadData(),
      child: MaterialApp(
        title: 'Brown Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D4E37),
            primary: const Color(0xFF5D4E37),
            secondary: const Color(0xFFA0826D),
          ),
          scaffoldBackgroundColor: const Color(0xFFFBF8F3),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const StartPage(), const StatsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF5D4E37),
        unselectedItemColor: const Color(0xFFA0826D),
        backgroundColor: const Color(0xFFFBF8F3),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Start"),
            selectedColor: const Color(0xFF5D4E37),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.bar_chart),
            title: const Text("Stats"),
            selectedColor: const Color(0xFF5D4E37),
          ),
        ],
      ),
    );
  }
}
