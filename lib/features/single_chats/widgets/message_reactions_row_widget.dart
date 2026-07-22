import 'package:flutter/material.dart';
import '../../reactions/widgets/reactions_summary_pill.dart';

class MessageReactionsRow extends StatelessWidget {
  final Map<String, String> reactions;
  final String currentUserId;
  final Color primary;
  final VoidCallback? onTap;

  const MessageReactionsRow({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReactionsSummaryPill(
      reactions: reactions,
      currentUserId: currentUserId,
      primary: primary,
      onTap: onTap,
    );
  }
}
