import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showSearch;
  final VoidCallback? onSearchTap;
  final List<Widget>? actions;

  const PrimaryAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSearch = false,
    this.onSearchTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(title, style: AppTypography.bodyBold),
      centerTitle: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchTap,
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
