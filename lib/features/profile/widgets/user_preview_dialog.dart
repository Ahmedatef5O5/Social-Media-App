import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/calls/call_icon_button.dart';
import '../../single_calls/model/call_model.dart';
import '../../single_chats/services/chat_block_service.dart';

class UserPreviewDialog extends StatefulWidget {
  final ChatUserModel user;
  final bool showContactOptions;
  const UserPreviewDialog({
    super.key,
    required this.user,
    this.showContactOptions = false,
  });

  @override
  State<UserPreviewDialog> createState() => _UserPreviewDialogState();
}

class _UserPreviewDialogState extends State<UserPreviewDialog> {
  bool? _isBlocked;

  @override
  void initState() {
    super.initState();
    if (widget.showContactOptions) {
      _loadBlockStatus();
    }
  }

  Future<void> _loadBlockStatus() async {
    final status = await ChatBlockService().getBlockStatus(
      currentUserId: SupabaseProvider.id,
      otherUserId: widget.user.id,
    );
    if (!mounted) return;
    setState(() => _isBlocked = status.isBlocked);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final iconColor = Theme.of(context).primaryColor;
    final screenSize = MediaQuery.sizeOf(context);

    final horizontalInset = (screenSize.width * 0.14).clamp(45.0, 80.0);
    final dialogWidth = screenSize.width - (horizontalInset * 2);

    final imageHeight = (dialogWidth).clamp(220.0, 340.0);

    return Dialog(
      alignment: const Alignment(0, -0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: user.id,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.fullScreenImageViewRoute,
                  arguments: {
                    'url':
                        (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                            ? user.imageUrl!
                            : AppImages.defaultUserImg,
                    'tag': user.id,
                    'isAsset': user.imageUrl == null || user.imageUrl!.isEmpty,
                  },
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      child:
                          (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                              ? CachedCloudinaryImage(
                                secureUrl: user.imageUrl!,
                                fit: BoxFit.cover,
                                height: imageHeight,
                                width: double.infinity,
                                isAvatar: true,
                                placeholder:
                                    (context) => SizedBox(
                                      height: imageHeight,
                                      child: const Center(
                                        child: CustomLoadingIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, error) => Image.asset(
                                      AppImages.defaultUserImg,
                                      fit: BoxFit.fitWidth,
                                    ),
                              )
                              : Image.asset(
                                AppImages.defaultUserImg,
                                fit: BoxFit.fitWidth,
                                height: imageHeight,
                                width: double.infinity,
                              ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.message_outlined, color: iconColor),
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.chatDetailsViewRoute,
                      arguments: user,
                    );
                  },
                ),
                if (widget.showContactOptions) ...[
                  CallIconButton(
                    type: CallType.audio,
                    receiverId: user.id,
                    receiverName: user.name,
                    receiverAvatar: user.imageUrl ?? '',
                    isBlocked: _isBlocked ?? true,
                  ),
                  CallIconButton(
                    type: CallType.video,
                    receiverId: user.id,
                    receiverName: user.name,
                    receiverAvatar: user.imageUrl ?? '',
                    isBlocked: _isBlocked ?? true,
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.info_outline, color: iconColor),
                  onPressed: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.profileViewRoute, arguments: user.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
