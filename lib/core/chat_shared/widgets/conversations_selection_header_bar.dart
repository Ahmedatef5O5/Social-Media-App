import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/conversations_cubit/conversations_cubit.dart';
import '../models/conversation_ref.dart';
import 'premium_selection_bar_pieces.dart';

class ConversationsSelectionHeaderBar extends StatelessWidget {
  final Set<ConversationRef> selectedRefs;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const ConversationsSelectionHeaderBar({
    super.key,
    required this.selectedRefs,
    required this.onCancel,
    required this.onDelete,
  });

  Future<void> _runAndClose(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    await action();
    if (context.mounted) onCancel();
  }

  Widget _toggleAction(
    BuildContext context,
    ConversationsCubit cubit, {
    required SelectionFlagState flagState,
    required IconData onIcon,
    required IconData offIcon,
    required String onLabel,
    required String offLabel,
    required Future<void> Function(bool) apply,
    bool hideOnMixed = false,
  }) {
    final isMixed = flagState == SelectionFlagState.mixed;

    if (isMixed && hideOnMixed) return const SizedBox.shrink();

    final isOn = flagState == SelectionFlagState.allOn;
    return PremiumSelectionActionIcon(
      state:
          isMixed
              ? PremiumActionVisualState.mixed
              : (isOn
                  ? PremiumActionVisualState.on
                  : PremiumActionVisualState.off),
      onIcon: onIcon,
      offIcon: offIcon,
      onLabel: onLabel,
      offLabel: offLabel,
      onTap: isMixed ? null : () => _runAndClose(context, () => apply(!isOn)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationsCubit>();
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            count: selectedRefs.length,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const Spacer(),

          _toggleAction(
            context,
            cubit,
            flagState: cubit.mutedState(selectedRefs),
            onIcon: Icons.notifications_active_outlined,
            offIcon: Icons.notifications_off_rounded,
            onLabel: 'Unmute',
            offLabel: 'Mute',
            hideOnMixed: true,
            apply: (v) => cubit.bulkSetMuted(selectedRefs, v),
          ),

          _toggleAction(
            context,
            cubit,
            flagState: cubit.favoriteState(selectedRefs),
            onIcon: Icons.star_rounded,
            offIcon: Icons.star_border_rounded,
            onLabel: 'Unstar',
            offLabel: 'Star',
            apply: (v) => cubit.bulkSetFavorite(selectedRefs, v),
          ),

          _toggleAction(
            context,
            cubit,
            flagState: cubit.pinnedState(selectedRefs),
            onIcon: Icons.push_pin_rounded,
            offIcon: Icons.push_pin_outlined,
            onLabel: 'Unpin',
            offLabel: 'Pin',
            apply: (v) => cubit.bulkSetPinned(selectedRefs, v),
          ),

          _toggleAction(
            context,
            cubit,
            flagState: cubit.archivedState(selectedRefs),
            onIcon: Icons.unarchive_rounded,
            offIcon: Icons.archive_outlined,
            onLabel: 'Unarchive',
            offLabel: 'Archive',
            apply: (v) => cubit.bulkSetArchived(selectedRefs, v),
          ),

          PremiumSelectionActionIcon(
            state: PremiumActionVisualState.on,
            onIcon: Icons.delete_outline_rounded,
            onLabel: 'Delete',
            isDestructive: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
