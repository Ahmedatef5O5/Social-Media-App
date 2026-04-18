import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class StoryTextEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;

  const StoryTextEditor({
    super.key,
    required this.controller,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SingleChildScrollView(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            maxLines: null,
            maxLength: 180,
            style: const TextStyle(color: AppColors.white, fontSize: 32),
            decoration: InputDecoration(
              hintText: 'Write your thought with others',
              hintStyle: const TextStyle(
                color: AppColors.white70,
                fontSize: 32,
              ),
              border: InputBorder.none,
              counterText: hasText ? null : '',
            ),
          ),
        ),
      ),
    );
  }
}
