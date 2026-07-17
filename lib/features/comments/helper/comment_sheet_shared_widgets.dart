import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../model/comment_sort_option.dart';

class CommentSortMenu extends StatelessWidget {
  final CommentSortOption current;
  final ValueChanged<CommentSortOption> onChanged;

  const CommentSortMenu({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<CommentSortOption>(
      initialValue: current,
      onSelected: onChanged,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      icon: Icon(Icons.sort_rounded, color: AppColors.grey7, size: 26),
      itemBuilder:
          (context) =>
              CommentSortOption.values.map((option) {
                final isSelected = current == option;

                return PopupMenuItem<CommentSortOption>(
                  value: option,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option.icon,
                        size: 20,
                        color:
                            isSelected ? theme.primaryColor : AppColors.grey6,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color:
                              isSelected
                                  ? theme.primaryColor
                                  : (isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(width: 24),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: theme.primaryColor,
                        )
                      else
                        const SizedBox(width: 18),
                    ],
                  ),
                );
              }).toList(),
    );
  }
}
