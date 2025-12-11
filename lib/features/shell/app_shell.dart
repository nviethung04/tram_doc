import 'package:flutter/material.dart';
import '../../components/bottom_nav.dart';
import '../../features/library/library_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/circle/circle_screen.dart';
import '../../features/profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  MainTab current = MainTab.library;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: current.index,
        children: const [
          LibraryScreen(),
          NotesScreen(),
          CircleScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        current: current,
        onChanged: (tab) => setState(() => current = tab),
      ),
    );
  }
}
