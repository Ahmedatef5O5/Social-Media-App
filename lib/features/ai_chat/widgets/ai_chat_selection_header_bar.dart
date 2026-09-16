import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/chat_shared/widgets/premium_selection_bar_pieces.dart';

const Color kAiChatStarGold = Color(0xFFFFD700);

class AiChatSelectionHeaderBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final bool showStar;
  final bool isStarred;
  final VoidCallback onStarToggle;
  final VoidCallback onShareTap;
  final VoidCallback onForwardTap;
  final VoidCallback onInfoTap;
  final VoidCallback onCopyTap;
  const AiChatSelectionHeaderBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.showStar,
    required this.isStarred,
    required this.onStarToggle,
    required this.onShareTap,
    required this.onForwardTap,
    required this.onInfoTap,
    required this.onCopyTap,
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
            // [FIX] Was colorScheme.onSurface, which doesn't reliably read
            // against this header's translucent pill over the dark Syncra
            // backdrop. White matches every other text/icon color already
            // used throughout AiChatView (the "Syncra" title, bubble text).
            PremiumSelectionCountLabel(
              count: selectedCount,
              color: Colors.white,
            ),
            const Spacer(),

            // Share — hands the combined text of the selected messages to
            // the OS share sheet. On both iOS and Android that sheet's own
            // action list includes "Copy", so this single action already
            // covers "copy selected text OR native OS share" without us
            // needing two separate buttons for it.
            PremiumSelectionActionIcon(
              state: PremiumActionVisualState.off,
              onIcon: CupertinoIcons.paperplane,
              offIcon: CupertinoIcons.paperplane,
              onLabel: 'Share',
              offLabel: 'Share',
              onTap: onShareTap,
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
              state: PremiumActionVisualState.off,
              onIcon: Icons.copy_rounded,
              offIcon: Icons.copy_rounded,
              onLabel: 'Copy',
              offLabel: 'Copy',
              onTap: onCopyTap,
            ),

            // Star — collapsed to zero width/opacity (not merely disabled)
            // the instant the selection's star-state is mixed, restored
            // just as smoothly the instant it agrees again. Gold, not the
            // app's primary color, when active — the traditional star
            // color, matching the per-bubble badge (kAiChatStarGold).
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showStar ? 1 : 0,
                child: SizedBox(
                  width: showStar ? null : 0,
                  child: IgnorePointer(
                    ignoring: !showStar,
                    child: PremiumSelectionActionIcon(
                      state:
                          isStarred
                              ? PremiumActionVisualState.on
                              : PremiumActionVisualState.off,
                      onIcon: Icons.star_rounded,
                      offIcon: Icons.star_border_rounded,
                      onLabel: 'Unstar',
                      offLabel: 'Star',
                      activeColor: isStarred ? kAiChatStarGold : null,
                      onTap: onStarToggle,
                    ),
                  ),
                ),
              ),
            ),

            PremiumSelectionActionIcon(
              state: PremiumActionVisualState.off,
              onIcon: Icons.info_outline,
              offIcon: Icons.info_outline,
              onLabel: 'Info',
              offLabel: 'Info',
              onTap: onInfoTap,
            ),
          ],
        ),
      ),
    );
  }
}
