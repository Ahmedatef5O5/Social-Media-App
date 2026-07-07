import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class GroupHeaderSection extends StatelessWidget {
  final File? groupImage;
  final VoidCallback onPickImage;
  final TextEditingController controller;
  final Color primary;
  final bool isDark;

  const GroupHeaderSection({
    super.key,
    required this.groupImage,
    required this.onPickImage,
    required this.controller,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: CircleAvatar(
              radius: 38,
              backgroundColor: primary.withValues(alpha: 0.15),
              backgroundImage:
                  groupImage != null ? FileImage(groupImage!) : null,
              child:
                  groupImage == null
                      ? Icon(Icons.group_rounded, color: primary)
                      : null,
            ),
          ),
          const Gap(16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
