import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SelectedMembersSection extends StatelessWidget {
  final Set<String> selectedUserIds;
  final List<Map<String, dynamic>> allUsers;
  final Color primary;
  final Function(String) onRemove;

  const SelectedMembersSection({
    super.key,
    required this.selectedUserIds,
    required this.allUsers,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedUserIds.isEmpty) return const SizedBox();

    return Container(
      height: 100,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: selectedUserIds.length,
        itemBuilder: (context, index) {
          final uid = selectedUserIds.elementAt(index);
          final user = allUsers.firstWhere(
            (u) => u['id'] == uid,
            orElse: () => {'id': uid, 'name': '?', 'image_url': null},
          );
          final name = user['name'] as String? ?? '';
          final imageUrl = user['image_url'] as String?;

          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () => onRemove(uid),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? CachedNetworkImageProvider(imageUrl)
                                : null,
                        child:
                            (imageUrl == null || imageUrl.isEmpty)
                                ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 56,
                    child: Text(
                      name.split(' ').first,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
