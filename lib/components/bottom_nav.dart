import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum MainTab { library, notes, circle, profile }

class BottomNavBar extends StatelessWidget {
  final MainTab current;
  final ValueChanged<MainTab> onChanged;
  const BottomNavBar({super.key, required this.current, required this.onChanged});

  BottomNavigationBarItem _item(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: current.index,
      onTap: (i) => onChanged(MainTab.values[i]),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: AppTypography.caption,
      unselectedLabelStyle: AppTypography.caption,
      items: [
        _item(Icons.menu_book_outlined, 'Library'),
        _item(Icons.note_alt_outlined, 'Notes'),
        _item(Icons.groups_outlined, 'Circle'),
        _item(Icons.person_outline, 'Profile'),
      ],
    );
  }
}
