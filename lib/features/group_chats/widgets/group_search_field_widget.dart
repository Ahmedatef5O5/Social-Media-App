import 'package:flutter/material.dart';

class GroupSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const GroupSearchField({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search people',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor:
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
