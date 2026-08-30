import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../helpers/comment_menu_action.dart';

class CommentActionMenu extends StatelessWidget {
  final List<CommentMenuAction> actions;
  const CommentActionMenu({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color:
              theme.brightness == Brightness.dark
                  ? theme.colorScheme.surface
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              InkWell(
                onTap: actions[i].onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        actions[i].icon,
                        size: 19,
                        color: actions[i].color ?? theme.iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        actions[i].label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: actions[i].color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i != actions.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.grey5.withValues(alpha: 0.2),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
