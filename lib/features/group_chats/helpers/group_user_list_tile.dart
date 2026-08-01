import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class GroupUserListTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelected;
  final Color primary;
  final VoidCallback onTap;

  const GroupUserListTile({
    super.key,
    required this.user,
    required this.isSelected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? 'Unknown';
    final imageUrl = user['image_url'] as String?;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      highlightColor: primary.withValues(alpha: 0.05),
      splashColor: primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primary.withValues(alpha: 0.1),
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
            const Gap(16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primary : Colors.grey.shade300,
                  width: isSelected ? 0 : 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child:
                  isSelected
                      ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
