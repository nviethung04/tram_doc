import 'package:flutter/material.dart';

import '../../components/empty_state.dart';
import '../../components/primary_app_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedIndex = 0; // 0: Thông báo, 1: Lời mời

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Thông báo', showBack: true),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SegmentedControl(
              currentIndex: _selectedIndex,
              onChanged: (index) => setState(() => _selectedIndex = index),
              labels: const ['Thông báo', 'Lời mời'],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedIndex == 0
                  ? const _NotificationsTab(key: ValueKey('notifications_tab'))
                  : const _InvitesTab(key: ValueKey('invites_tab')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const _SegmentedControl({
    required this.currentIndex,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(String label, int index) {
      final selected = currentIndex == index;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(index),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: selected ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          item(labels[0], 0),
          item(labels[1], 1),
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'Chưa có thông báo',
      description: 'Khi có thông báo mới, bạn sẽ thấy ở đây.',
    );
  }
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.mail_outline,
      title: 'Chưa có lời mời',
      description: 'Lời mời kết bạn sẽ hiển thị ở đây.',
    );
  }
}
