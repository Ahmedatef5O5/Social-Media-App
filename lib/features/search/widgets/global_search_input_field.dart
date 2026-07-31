import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlobalSearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<String> queryListenable;
  final VoidCallback onClear;

  const GlobalSearchInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.queryListenable,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search accounts, posts, reels...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.primaryColor,
            size: 21,
          ),
          suffixIcon: ValueListenableBuilder<String>(
            valueListenable: queryListenable,
            builder: (context, query, _) {
              if (query.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onClear,
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}
