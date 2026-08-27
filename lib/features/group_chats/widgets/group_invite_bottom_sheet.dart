import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/design/components/app_bottom_sheet.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/theme/theme_extensions.dart';
import '../../../core/design/tokens/dimensions.dart';
import '../../../core/design/tokens/radii.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/notification_services.dart' show navigatorKey;
import '../../../core/toast/app_toast.dart';
import '../models/group_invite_preview.dart';
import '../services/group_chat_services.dart';

class GroupInviteBottomSheet extends StatefulWidget {
  final String inviteHash;

  const GroupInviteBottomSheet({super.key, required this.inviteHash});

  static Future<void> show(BuildContext context, String inviteHash) {
    return AppBottomSheet.show(
      context: context,
      builder: (_) => GroupInviteBottomSheet(inviteHash: inviteHash),
    );
  }

  @override
  State<GroupInviteBottomSheet> createState() => _GroupInviteBottomSheetState();
}

class _GroupInviteBottomSheetState extends State<GroupInviteBottomSheet> {
  final _services = GroupChatServices();

  bool _isLoading = true;
  bool _isJoining = false;
  GroupInvitePreview? _preview;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await _services.getGroupInvitePreview(widget.inviteHash);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = SupabaseErrorMapper.toUserMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _join() async {
    setState(() => _isJoining = true);
    try {
      final group = await _services.joinGroupViaInvite(widget.inviteHash);
      if (!mounted) return;
      Navigator.of(context).pop();
      navigatorKey.currentState?.pushNamed(
        AppRoutes.groupChatRoute,
        arguments: group,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _openExistingChat() async {
    final groupId = _preview?.groupId;
    if (groupId == null) return;

    Navigator.of(context).pop();
    try {
      final groups = await _services.getMyGroups();
      final matches = groups.where((g) => g.id == groupId);
      final group = matches.isNotEmpty ? matches.first : null;
      if (group == null) {
        AppToast.warning('This group is no longer available');
        return;
      }
      navigatorKey.currentState?.pushNamed(
        AppRoutes.groupChatRoute,
        arguments: group,
      );
    } catch (e) {
      AppToast.error('Failed to open group chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const _InvitePreviewShimmer();
    }

    final preview = _preview;
    final invalid =
        _errorMessage != null || preview == null || !preview.isValid;

    if (invalid) {
      return _InvalidInviteContent(
        message: _errorMessage ?? 'This invite link is no longer valid',
        onClose: () => Navigator.of(context).pop(),
      );
    }

    return _ValidInviteContent(
      preview: preview,
      isJoining: _isJoining,
      onJoin: _join,
      onOpenChat: _openExistingChat,
    );
  }
}

class _InvalidInviteContent extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _InvalidInviteContent({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.link_off_rounded, size: 48, color: palette.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.typography.bodyLarge?.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Close',
          onPressed: onClose,
          variant: AppButtonVariant.secondary,
        ),
      ],
    );
  }
}

class _ValidInviteContent extends StatelessWidget {
  final GroupInvitePreview preview;
  final bool isJoining;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;

  const _ValidInviteContent({
    required this.preview,
    required this.isJoining,
    required this.onJoin,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const double avatarSize = AppDimensions.avatarXl; // 72px

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surfaceVariant,
            border: Border.all(
              color: palette.outline,
              width: AppDimensions.borderWidthDefault,
            ),
          ),
          child: ClipOval(
            child:
                (preview.groupAvatarUrl != null &&
                        preview.groupAvatarUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                      imageUrl: preview.groupAvatarUrl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Container(color: palette.surfaceVariant),
                      errorWidget:
                          (_, __, ___) => Image.asset(
                            AppImages.defaultGroupImg,
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(AppImages.defaultGroupImg, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          preview.groupName ?? 'Group',
          textAlign: TextAlign.center,
          style: context.typography.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.onSurface,
          ),
        ),
        if ((preview.groupTitle ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            preview.groupTitle!,
            textAlign: TextAlign.center,
            style: context.typography.bodyMedium?.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${preview.memberCount} member${preview.memberCount == 1 ? '' : 's'}',
          style: context.typography.bodySmall?.copyWith(
            color: palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (preview.isAlreadyMember)
          AppButton(text: 'Open Chat', onPressed: onOpenChat)
        else
          AppButton(
            text: 'Join Group',
            onPressed: onJoin,
            isLoading: isJoining,
          ),
      ],
    );
  }
}

/// Shimmer Skeleton Animation
class _InvitePreviewShimmer extends StatefulWidget {
  const _InvitePreviewShimmer();

  @override
  State<_InvitePreviewShimmer> createState() => _InvitePreviewShimmerState();
}

class _InvitePreviewShimmerState extends State<_InvitePreviewShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;

    final baseColor =
        isDark
            ? palette.surfaceVariant.withValues(alpha: 0.6)
            : palette.surfaceVariant;
    final highlightColor =
        isDark
            ? palette.surfaceVariant.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlidingGradientTransform(slidePercent: _controller.value),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Placeholder (Circle 72x72)
            Container(
              width: AppDimensions.avatarXl,
              height: AppDimensions.avatarXl,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
              ),
            ),
            const SizedBox(height: 16),

            // Group Name Placeholder
            Container(
              width: 160,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: AppRadii.radiusSm,
                gradient: gradient,
              ),
            ),
            const SizedBox(height: 8),

            // Members Count Placeholder
            Container(
              width: 90,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: AppRadii.radiusXs,
                gradient: gradient,
              ),
            ),
            const SizedBox(height: 24),

            // Button Placeholder
            Container(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              decoration: BoxDecoration(
                borderRadius: AppRadii.radiusMd,
                gradient: gradient,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
