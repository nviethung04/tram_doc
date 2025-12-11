import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LabeledInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;

  const LabeledInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}

class SearchBarInput extends StatelessWidget {
  final String hint;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;

  const SearchBarInput({
    super.key,
    this.onFilterTap,
    this.onChanged,
    this.hint = 'Tìm kiếm...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: onFilterTap != null
            ? IconButton(
                icon: const Icon(Icons.tune, color: AppColors.textMuted),
                onPressed: onFilterTap,
              )
            : null,
        hintText: hint,
      ),
    );
  }
}
