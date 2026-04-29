import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Set<String> selectedIds;
  final Color primary;
  final bool isDark;
  final Function(String) onToggle;

  const UsersList({
    super.key,
    required this.users,
    required this.selectedIds,
    required this.primary,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        final uid = user['id'] as String;
        final name = user['name'] as String? ?? '';
        final imageUrl = user['image_url'] as String?;
        final selected = selectedIds.contains(uid);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Stack(
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
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              if (selected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 9,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing:
              selected
                  ? Icon(Icons.check_circle, color: primary, size: 22)
                  : Icon(
                    Icons.circle_outlined,
                    color: isDark ? Colors.white38 : Colors.black26,
                    size: 22,
                  ),
          onTap: () => onToggle(uid),
        );
      },
    );
  }
}
