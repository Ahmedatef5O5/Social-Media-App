import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feedback_models.dart';

class FeedbackCategorySelector extends StatelessWidget {
  final FeedbackCategory selected;
  final ValueChanged<FeedbackCategory> onSelected;

  const FeedbackCategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FeedbackCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = FeedbackCategory.values[i];
          final isSel = c == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(c);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color:
                    isSel
                        ? primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color:
                      isSel
                          ? primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    c.icon,
                    size: 16,
                    color:
                        isSel
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color:
                          isSel
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
