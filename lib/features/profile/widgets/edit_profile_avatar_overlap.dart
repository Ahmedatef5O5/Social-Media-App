import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_avatar.dart';

class EditProfileAvatarCircle extends StatelessWidget {
  final double avatarSize;
  final String? avatarUrl;
  final File? selectedAvatarFile;
  final VoidCallback onEditAvatar;

  const EditProfileAvatarCircle({
    super.key,
    required this.avatarSize,
    required this.onEditAvatar,
    this.avatarUrl,
    this.selectedAvatarFile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditAvatar,
      child: Hero(
        tag: 'edit-profile-avatar',
        child: Container(
          width: avatarSize - 6,
          height: avatarSize - 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.72),
              width: 0.75,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child:
                    selectedAvatarFile != null
                        ? Image.file(
                          selectedAvatarFile!,
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                        )
                        : AppAvatar(imageUrl: avatarUrl, size: avatarSize - 8),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.22),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                  size: avatarSize * 0.125,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
