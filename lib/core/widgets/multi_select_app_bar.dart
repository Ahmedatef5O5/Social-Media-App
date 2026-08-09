import 'package:flutter/material.dart';
import '../chat_shared/widgets/premium_selection_bar_pieces.dart';

class MultiSelectAction {
  final IconData icon;
  final Color? color;
  final String? tooltip;
  final bool isDestructive;
  final VoidCallback? onPressed;

  const MultiSelectAction({
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
    this.isDestructive = false,
  });
}

class MultiSelectChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final List<MultiSelectAction> actions;

  const MultiSelectChatAppBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      bottom: false,
      child: Container(
        height: kToolbarHeight,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.16 : 0.08),
          border: Border(
            bottom: BorderSide(
              color: primary.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            PremiumSelectionCloseButton(onPressed: onCancel, color: primary),
            const SizedBox(width: 2),
            PremiumSelectionCountLabel(count: selectedCount, color: onSurface),
            const Spacer(),
            for (final action in actions)
              PremiumSelectionActionIcon(
                state: PremiumActionVisualState.on,
                onIcon: action.icon,
                onLabel: action.tooltip ?? '',
                isDestructive:
                    action.isDestructive || action.color == Colors.red,
                activeColor: action.color,
                onTap: action.onPressed,
              ),
          ],
        ),
      ),
    );
  }
}
