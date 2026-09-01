import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import '../../../features/ai_chat/views/ai_chat_view.dart';
import '../../../features/chat_forwarding/models/forward_target_selection.dart';
import '../../../features/chat_forwarding/models/forwardable_message.dart';
import '../../../features/chat_forwarding/services/forward_service.dart';
import '../../../features/chat_forwarding/views/forward_target_picker_view.dart';
import '../../notifications/notification_navigator_key.dart';
import '../../supabase/supabase_provider.dart';
import '../../toast/app_toast.dart';

class ShareContentBottomSheet {
  ShareContentBottomSheet._();

  static Future<void> show(
    BuildContext context, {
    required String url,
    required String shareText,
    String? originalAuthorId,
    String? originalAuthorName,
    String? originalAuthorAvatarUrl,
    VoidCallback? onShared,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _ShareContentSheet(
            url: url,
            shareText: shareText,
            originalAuthorId: originalAuthorId,
            originalAuthorName: originalAuthorName,
            originalAuthorAvatarUrl: originalAuthorAvatarUrl,
            onShared: onShared,
          ),
    );
  }
}

class _ShareContentSheet extends StatelessWidget {
  final String url;
  final String shareText;
  final String? originalAuthorId;
  final String? originalAuthorName;
  final String? originalAuthorAvatarUrl;
  final VoidCallback? onShared;

  const _ShareContentSheet({
    required this.url,
    required this.shareText,
    this.originalAuthorId,
    this.originalAuthorName,
    this.originalAuthorAvatarUrl,
    this.onShared,
  });

  Future<void> _copyLink(BuildContext context) async {
    Navigator.pop(context);
    await Clipboard.setData(ClipboardData(text: url));
    AppToast.success('Link copied');
    onShared?.call();
  }

  Future<void> _forward(BuildContext context) async {
    Navigator.pop(context);

    final currentUserId = SupabaseProvider.id;

    final result = await navigatorKey.currentState
        ?.push<ForwardTargetSelection>(
          MaterialPageRoute(builder: (_) => const ForwardTargetPickerView()),
        );
    if (result == null || result.isEmpty) return;

    if (result.toAi) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AiChatView(initialDraftText: shareText),
        ),
      );
      onShared?.call();
      return;
    }

    final message = ForwardableMessage(
      originalSenderId: originalAuthorId ?? currentUserId,
      originalSenderName: originalAuthorName ?? 'You',
      originalSenderAvatar: originalAuthorAvatarUrl,
      text: shareText,
      messageType: 'text',
    );

    try {
      await ForwardService().forwardMessages(
        messages: [message],
        targets: result,
        currentUserId: currentUserId,
      );
      AppToast.info('Forwarded to ${result.length} chat(s)');
    } catch (e) {
      AppToast.info('Failed to forward. Try again.');
    }
  }

  void _shareExternally(BuildContext context) {
    Navigator.pop(context);
    SharePlus.instance.share(ShareParams(text: shareText));
    onShared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 25,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(12),
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _ShareOptionTile(
                    icon: Icons.copy_rounded,
                    title: 'Copy Link',
                    color: const Color(0xFF4CAF50),
                    onTap: () => _copyLink(context),
                  ),
                  _ShareOptionTile(
                    icon: Icons.forward_rounded,
                    title: 'Forward to Chat',
                    color: const Color(0xFF2196F3),
                    onTap: () => _forward(context),
                  ),
                  _ShareOptionTile(
                    icon: Icons.ios_share_rounded,
                    title: 'Share via...',
                    color: const Color(0xFFFF9800),
                    onTap: () => _shareExternally(context),
                  ),
                ],
              ),
            ),
            const Gap(12),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: color.withValues(alpha: 0.05),
          splashColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
