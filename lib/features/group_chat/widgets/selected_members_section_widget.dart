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
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children:
            selectedUserIds.map((uid) {
              final user = allUsers.firstWhere(
                (u) => u['id'] == uid,
                orElse: () => {'id': uid, 'name': '?', 'image_url': null},
              );
              final name = user['name'] as String? ?? '';
              final imageUrl = user['image_url'] as String?;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onRemove(uid),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: primary.withValues(alpha: 0.12),
                            backgroundImage:
                                (imageUrl != null && imageUrl.isNotEmpty)
                                    ? CachedNetworkImageProvider(imageUrl)
                                    : null,
                            child:
                                (imageUrl == null || imageUrl.isEmpty)
                                    ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(color: primary),
                                    )
                                    : null,
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name.length > 5 ? '${name.substring(0, 5)}..' : name,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
