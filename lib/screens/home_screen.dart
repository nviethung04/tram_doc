import 'package:flutter/material.dart';
import 'package:tram_doc/screens/library/library_screen.dart';
import 'package:tram_doc/screens/notes/notes_screen.dart';
import 'package:tram_doc/screens/review/review_screen.dart';
import 'package:tram_doc/screens/circle/circle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(),
    const NotesScreen(),
    const ReviewScreen(),
    const CircleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Ghi chú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Ôn tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Vòng tròn',
          ),
        ],
      ),
    );
  }
}

