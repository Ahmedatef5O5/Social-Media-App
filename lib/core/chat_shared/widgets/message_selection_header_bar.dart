import 'package:flutter/material.dart';
import 'premium_selection_bar_pieces.dart';

class MessageSelectionHeaderBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final bool showStar;
  final bool isStarred;
  final VoidCallback onStarToggle;
  final VoidCallback onInfoTap;
  final VoidCallback onForwardTap;
  final VoidCallback onDeleteTap;

  const MessageSelectionHeaderBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.showStar,
    required this.isStarred,
    required this.onStarToggle,
    required this.onInfoTap,
    required this.onForwardTap,
    required this.onDeleteTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            PremiumSelectionCloseButton(onPressed: onCancel, color: primary),
            const SizedBox(width: 4),
            PremiumSelectionCountLabel(
              count: selectedCount,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const Spacer(),

            if (showStar)
              PremiumSelectionActionIcon(
                state:
                    isStarred
                        ? PremiumActionVisualState.on
                        : PremiumActionVisualState.off,
                onIcon: Icons.star_rounded,
                offIcon: Icons.star_border_rounded,
                onLabel: 'Unstar',
                offLabel: 'Star',
                onTap: onStarToggle,
              ),

            PremiumSelectionActionIcon(
              state: PremiumActionVisualState.off,
              onIcon: Icons.info_outline,
              offIcon: Icons.info_outline,
              onLabel: 'Info',
              offLabel: 'Info',
              onTap: onInfoTap,
            ),

            PremiumSelectionActionIcon(
              state: PremiumActionVisualState.off,
              onIcon: Icons.shortcut_rounded,
              offIcon: Icons.shortcut_rounded,
              onLabel: 'Forward',
              offLabel: 'Forward',
              onTap: onForwardTap,
            ),

            PremiumSelectionActionIcon(
              state: PremiumActionVisualState.on,
              onIcon: Icons.delete_outline_rounded,
              onLabel: 'Delete',
              isDestructive: true,
              onTap: onDeleteTap,
            ),
          ],
        ),
      ),
    );
  }
}
