import 'package:flutter/material.dart';
import '../cubits/chat_details_cubit/chat_details_cubit.dart';
import '../models/chat_block_status.dart';
import '../views/chat_details_view.dart';

class BlockedSingleChatBarWidget extends StatelessWidget {
  final ChatDetailsView widget;
  final ChatDetailsCubit _chatCubit;
  final String _receiverId;
  final BuildContext context;
  final ChatBlockStatus status;

  const BlockedSingleChatBarWidget({
    super.key,
    required this.widget,
    required ChatDetailsCubit chatCubit,
    required String receiverId,
    required this.context,
    required this.status,
  }) : _chatCubit = chatCubit,
       _receiverId = receiverId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.error.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.block_rounded, color: scheme.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Blocked',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.blockedByMe
                      ? "You can't message ${widget.receiverUser.name} until you unblock them."
                      : "You can't reply to this conversation.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (status.blockedByMe) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                visualDensity: VisualDensity.compact,
              ),
              onPressed:
                  () => _chatCubit.toggleBlock(
                    receiverId: _receiverId,
                    otherUserName: widget.receiverUser.name,
                  ),
              child: const Text('Unblock'),
            ),
          ],
        ],
      ),
    );
  }
}
