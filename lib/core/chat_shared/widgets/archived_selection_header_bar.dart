import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/conversations_cubit/conversations_cubit.dart';
import '../models/conversation_ref.dart';
import 'premium_selection_bar_pieces.dart';

class ArchivedSelectionHeaderBar extends StatelessWidget {
  final Set<ConversationRef> selectedRefs;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const ArchivedSelectionHeaderBar({
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
  }) {
    final isMixed = flagState == SelectionFlagState.mixed;
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

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 0,
      title: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
              flagState: cubit.archivePinnedState(selectedRefs),
              onIcon: Icons.push_pin_rounded,
              offIcon: Icons.push_pin_outlined,
              onLabel: 'Unpin',
              offLabel: 'Pin',
              apply: (v) => cubit.bulkSetArchivePinned(selectedRefs, v),
            ),

            PremiumSelectionActionIcon(
              state: PremiumActionVisualState.off,
              onIcon: Icons.unarchive_rounded,
              offIcon: Icons.unarchive_rounded,
              onLabel: 'Unarchive',
              offLabel: 'Unarchive',
              onTap:
                  () => _runAndClose(
                    context,
                    () => cubit.bulkSetArchived(selectedRefs, false),
                  ),
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
      ),
    );
  }
}
