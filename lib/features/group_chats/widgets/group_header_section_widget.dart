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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    image:
                        groupImage != null
                            ? DecorationImage(
                              image: FileImage(groupImage!),
                              fit: BoxFit.cover,
                            )
                            : null,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child:
                      groupImage == null
                          ? Icon(Icons.groups_rounded, size: 36, color: primary)
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Enter group name',
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
