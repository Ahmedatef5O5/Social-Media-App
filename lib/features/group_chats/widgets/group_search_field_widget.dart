import 'package:flutter/cupertino.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search people...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            size: 20,
          ),
          filled: true,
          fillColor:
              isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
