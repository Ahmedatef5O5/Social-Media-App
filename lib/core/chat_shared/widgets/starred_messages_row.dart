import 'package:flutter/material.dart';
import '../../cache/services/starred_message_store.dart';

class StarredMessagesRow extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;
  final String? currentUserId;
  final Set<String>? chatMessageIds;

  const StarredMessagesRow({
    super.key,
    required this.primary,
    required this.onTap,
    this.currentUserId,
    this.chatMessageIds,
  });

  Future<int> _resolveCount() async {
    final uid = currentUserId;
    final ids = chatMessageIds;
    if (uid == null || uid.isEmpty || ids == null || ids.isEmpty) {
      return 0;
    }
    final starredIds = await StarredMessagesStore.instance.getStarredMessageIds(
      uid,
    );
    var count = 0;
    for (final id in starredIds) {
      if (ids.contains(id)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.16 : 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Starred Messages',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (currentUserId != null && chatMessageIds != null)
              ValueListenableBuilder<int>(
                valueListenable: StarredMessagesStore.instance.changes,
                builder: (context, _, __) {
                  return FutureBuilder<int>(
                    future: _resolveCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return count > 0
                          ? Container(
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primary.withValues(
                                alpha: isDark ? 0.18 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primary,
                                height: 1.1,
                              ),
                            ),
                          )
                          : SizedBox.shrink();
                    },
                  );
                },
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
