import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../models/group_model.dart';

class GroupInfoHeader extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;
  final bool isEditingName;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSubmit;
  final VoidCallback onChangePhoto;

  const GroupInfoHeader({
    super.key,
    required this.group,
    required this.isAdmin,
    required this.isEditingName,
    required this.controller,
    required this.onEditTap,
    required this.onSubmit,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    // final primary = Theme.of(context).primaryColor;
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Gap(30),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    backgroundImage:
                        hasAvatar
                            ? CachedNetworkImageProvider(group.avatarUrl!)
                            : null,
                    child:
                        !hasAvatar
                            ? Text(
                              group.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                              ),
                            )
                            : null,
                  ),
                  if (isAdmin)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onChangePhoto,
                        child: Icon(Icons.camera_alt),
                      ),
                    ),
                ],
              ),
              const Gap(12),
              GestureDetector(
                onTap: isAdmin ? onEditTap : null,
                child:
                    isEditingName
                        ? TextField(
                          controller: controller,
                          onSubmitted: (_) => onSubmit(),
                        )
                        : Text(group.name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
