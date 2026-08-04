import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/social_graph/models/friend_list_item_model.dart';

class FriendPickerSheet extends StatelessWidget {
  final List<FriendListItemModel> friends;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const FriendPickerSheet({
    super.key,
    required this.friends,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share with',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(12),
            Expanded(
              child:
                  friends.isEmpty
                      ? const Center(child: CustomLoadingIndicator())
                      : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final isSelected = selectedIds.contains(
                            friend.user.id,
                          );
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => onToggle(friend.user.id),
                            title: Text(friend.user.name),
                            secondary: CircleAvatar(
                              backgroundImage:
                                  friend.user.imageUrl != null
                                      ? NetworkImage(friend.user.imageUrl!)
                                      : null,
                            ),
                          );
                        },
                      ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
