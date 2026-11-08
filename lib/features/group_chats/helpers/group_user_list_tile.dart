import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/app_image_provider.dart';

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

    final username = (user['username'] as String?)?.trim();
    final subtitle =
        (username != null && username.isNotEmpty)
            ? '@$username'
            : (user['bio'] as String?)?.trim();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color:
            isSelected ? primary.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: primary.withValues(alpha: 0.05),
        splashColor: primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primary.withValues(alpha: 0.1),
                backgroundImage:
                    (imageUrl != null && imageUrl.isNotEmpty)
                        ? AppImageProvider.avatar(imageUrl, radius: 24)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                  ],
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
      ),
    );
  }
}
