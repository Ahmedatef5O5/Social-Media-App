import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chats/helpers/group_preview_dialog.dart';
import '../../../core/chat_shared/cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../../../core/chat_shared/models/conversation_ref.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../helpers/last_message_group_preview.dart';
import '../models/group_model.dart';
import 'presence_animated_subtitle.dart';

class GroupTileItem extends StatelessWidget {
  final GroupModel group;
  final bool isPinned;
  final bool isFavorite;
  const GroupTileItem({
    super.key,
    required this.group,
    required this.isPinned,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;
    final highlightUnreadMessage =
        group.unreadCount > 0 && group.lastMessageSenderId != currentUserId;
    final ref = ConversationRef(type: ConversationType.group, id: group.id);

    return BlocBuilder<ConversationSelectionCubit, ConversationSelectionState>(
      builder: (context, selection) {
        final isSelecting = selection.isSelecting;
        final isSelected = selection.isSelected(ref);

        return Material(
          color:
              isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          child: InkWell(
            onLongPress:
                () => context.read<ConversationSelectionCubit>().toggle(ref),
            onTap: () {
              if (isSelecting) {
                context.read<ConversationSelectionCubit>().toggle(ref);
                return;
              }
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.groupChatRoute, arguments: group);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatarSection(
                    context,
                    hasAvatar,
                    isSelecting,
                    isSelected,
                    primary,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(8),
                            if (group.lastMessageAt != null)
                              _buildTimeText(context, primary, isDark),
                          ],
                        ),
                        const Gap(4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildSubtitleSection(
                                context,
                                currentUserId,
                                highlightUnreadMessage,
                                isDark,
                              ),
                            ),
                            const Gap(8),
                            _buildIconsSection(context, primary, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeText(BuildContext context, Color primary, bool isDark) {
    return Text(
      FormattedDate.getMessageTime(group.lastMessageAt!),
      style: TextStyle(
        color:
            group.unreadCount > 0
                ? primary
                : (isDark ? Colors.white38 : Colors.black38),
        fontSize: 11,
      ),
    );
  }

  Widget _buildIconsSection(BuildContext context, Color primary, bool isDark) {
    final hasStatusRow =
        isFavorite || isPinned || group.isMuted || group.unreadCount > 0;
    if (!hasStatusRow) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isFavorite) ...[
          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
          const Gap(4),
        ],
        if (isPinned) ...[
          Icon(
            Icons.push_pin_rounded,
            size: 15,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const Gap(4),
        ],
        if (group.isMuted) ...[
          FaIcon(
            FontAwesomeIcons.bellSlash,
            size: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          if (group.unreadCount > 0) const Gap(4),
        ],
        if (group.unreadCount > 0)
          Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitleSection(
    BuildContext context,
    String currentUserId,
    bool highlightUnreadMessage,
    bool isDark,
  ) {
    return PresenceAnimatedSubtitle(
      presence: group.presence,
      activeStyle: TextStyle(
        fontSize: 14,
        fontWeight: highlightUnreadMessage ? FontWeight.w500 : FontWeight.w400,
        color: Colors.green.shade600,
        fontStyle: FontStyle.italic,
      ),
      fallback:
          group.lastMessage != null
              ? Builder(
                builder: (context) {
                  final fullText = buildGroupLastMessagePreview(
                    group: group,
                    currentUserId: currentUserId,
                  );

                  String prefix = '';
                  String content = fullText;

                  final colonIndex = fullText.indexOf(': ');
                  if (colonIndex != -1 && colonIndex < 25) {
                    prefix = fullText.substring(0, colonIndex + 2);
                    content = fullText.substring(colonIndex + 2);
                  }

                  final direction = BidiTextHelper.detectDirection(
                    content.trimLeft(),
                  );

                  final textStyle = TextStyle(
                    color:
                        highlightUnreadMessage
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight:
                        highlightUnreadMessage
                            ? FontWeight.w500
                            : FontWeight.w400,
                  );

                  if (prefix.isEmpty) {
                    return Text(
                      content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: direction,
                      textAlign:
                          direction == TextDirection.rtl
                              ? TextAlign.right
                              : TextAlign.left,
                      style: textStyle,
                    );
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        prefix,
                        style: textStyle,
                        textDirection: TextDirection.ltr,
                      ),
                      Expanded(
                        child: Text(
                          content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: direction,
                          textAlign: TextAlign.left,
                          style: textStyle,
                        ),
                      ),
                    ],
                  );
                },
              )
              : Text(
                'Tap to open group chat',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
              ),
    );
  }

  Widget _buildAvatarSection(
    BuildContext context,
    bool hasAvatar,
    bool isSelecting,
    bool isSelected,
    Color primary,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap:
              (!isSelecting)
                  ? () => showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (_) => GroupPreviewDialog(group: group),
                  )
                  : null,
          child: ClipOval(
            child: Container(
              width: 52,
              height: 52,
              color: primary.withValues(alpha: 0.12),
              child:
                  hasAvatar
                      ? CachedCloudinaryImage(
                        secureUrl: group.avatarUrl!,
                        fit: BoxFit.cover,
                        isAvatar: true,
                        errorWidget:
                            (context, error) => Image.asset(
                              AppImages.defaultGroupImg,
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        AppImages.defaultGroupImg,
                        fit: BoxFit.cover,
                      ),
            ),
          ),
        ),
        if (isSelecting)
          Positioned(
            right: -2,
            bottom: -2,
            child: _SelectionBadge(isSelected: isSelected, primary: primary),
          ),
      ],
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final bool isSelected;
  final Color primary;
  const _SelectionBadge({required this.isSelected, required this.primary});

  @override
  Widget build(BuildContext context) {
    final ringColor = Theme.of(context).scaffoldBackgroundColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child:
            isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
      ),
    );
  }
}
