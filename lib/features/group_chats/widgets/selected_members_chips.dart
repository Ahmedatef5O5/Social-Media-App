import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SelectedMembersChips extends StatelessWidget {
  final Set<String> selectedUserIds;
  final List<Map<String, dynamic>> allUsers;
  final Color primary;
  final Function(String) onRemove;

  const SelectedMembersChips({
    super.key,
    required this.selectedUserIds,
    required this.allUsers,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedUserIds.isEmpty) return const SizedBox();

    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children:
            selectedUserIds.map((uid) {
              final user = allUsers.firstWhere(
                (u) => u['id'] == uid,
                orElse: () => {'name': 'Unknown', 'image_url': ''},
              );

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: primary.withValues(alpha: 0.15),
                          backgroundImage:
                              (user['image_url'] as String?)?.isNotEmpty == true
                                  ? CachedNetworkImageProvider(
                                    user['image_url'],
                                  )
                                  : null,
                          child:
                              (user['image_url'] as String?)?.isEmpty != false
                                  ? Text(
                                    (user['name'] as String)[0].toUpperCase(),
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: -1,
                          right: -1,
                          child: GestureDetector(
                            onTap: () => onRemove(uid),
                            child: const CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      (user['name'] as String).split(' ').first,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
