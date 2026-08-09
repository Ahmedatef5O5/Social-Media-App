import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/conversations_cubit/conversations_cubit.dart';
import '../models/conversation_ref.dart';

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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationsCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onCancel,
          ),
          Expanded(
            child: Text(
              '${selectedRefs.length} selected',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _SelectionActionIcon(
            state: cubit.mutedState(selectedRefs),
            onIcon: Icons.notifications_active_outlined,
            offIcon: Icons.notifications_off_rounded,
            onLabel: 'Unmute',
            offLabel: 'Mute',
            hideOnMixed: true,
            onTap:
                (target) => _runAndClose(
                  context,
                  () => cubit.bulkSetMuted(selectedRefs, target),
                ),
          ),
          _SelectionActionIcon(
            state: cubit.favoriteState(selectedRefs),
            onIcon: Icons.star_rounded,
            offIcon: Icons.star_border_rounded,
            onLabel: 'Unstar',
            offLabel: 'Star',
            onTap:
                (target) => _runAndClose(
                  context,
                  () => cubit.bulkSetFavorite(selectedRefs, target),
                ),
          ),
          _SelectionActionIcon(
            state: cubit.pinnedState(selectedRefs),
            onIcon: Icons.push_pin_rounded,
            offIcon: Icons.push_pin_outlined,
            onLabel: 'Unpin',
            offLabel: 'Pin',
            onTap:
                (target) => _runAndClose(
                  context,
                  () => cubit.bulkSetPinned(selectedRefs, target),
                ),
          ),
          _SelectionActionIcon(
            state: cubit.archivedState(selectedRefs),
            onIcon: Icons.unarchive_rounded,
            offIcon: Icons.archive_outlined,
            onLabel: 'Unarchive',
            offLabel: 'Archive',
            onTap:
                (target) => _runAndClose(
                  context,
                  () => cubit.bulkSetArchived(selectedRefs, target),
                ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SelectionActionIcon extends StatelessWidget {
  final SelectionFlagState state;
  final IconData onIcon;
  final IconData offIcon;
  final String onLabel;
  final String offLabel;
  final ValueChanged<bool> onTap;
  final bool hideOnMixed;

  const _SelectionActionIcon({
    required this.state,
    required this.onIcon,
    required this.offIcon,
    required this.onLabel,
    required this.offLabel,
    required this.onTap,
    this.hideOnMixed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMixed = state == SelectionFlagState.mixed;

    if (isMixed && hideOnMixed) return const SizedBox.shrink();

    final isOn = state == SelectionFlagState.allOn;
    return IconButton(
      tooltip: isMixed ? 'Mixed selection' : (isOn ? onLabel : offLabel),
      icon: Icon(isOn ? onIcon : offIcon),
      color: isMixed ? Theme.of(context).disabledColor : null,
      onPressed: isMixed ? null : () => onTap(!isOn),
    );
  }
}
