import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/chat_shared/helpers/avatar_stack.dart';
import '../../social_graph/models/content_privacy.dart';
import '../../social_graph/widgets/privacy_selector_sheet.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import '../helpers/create_pack_friend_picker.dart';
import '../model/sticker_pack_privacy.dart';

class CreateStickerPackPrivacySection extends StatelessWidget {
  final ThemeData theme;
  final CreateStickerPackForm state;
  final CreateStickerPackCubit cubit;
  final List<String> avatars;

  const CreateStickerPackPrivacySection({
    super.key,
    required this.theme,
    required this.state,
    required this.cubit,
    required this.avatars,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Privacy & Audience',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(12),

        InkWell(
          onTap: () async {
            FocusScope.of(context).unfocus();
            final result = await showPrivacySelectorSheet(
              context,
              currentPrivacy: state.privacy.toContentPrivacy(),
              isStory: false,
              isPack: true,
            );
            if (result != null) {
              cubit.setPrivacy(result.toStickerPackPrivacy());
              if (result == ContentPrivacy.friends ||
                  result == ContentPrivacy.private) {
                if (context.mounted) {
                  await showCreatePackFriendPicker(context);
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.privacy.toContentPrivacy().icon,
                    color: theme.primaryColor,
                    size: 22,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.privacy.toContentPrivacy().label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Tap to change audience',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.grey6,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey6),
              ],
            ),
          ),
        ),

        if (state.privacy == StickerPackPrivacy.friends ||
            state.privacy == StickerPackPrivacy.private) ...[
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (avatars.isNotEmpty) ...[
                  AvatarStack(
                    imageUrls: avatars,
                    maxVisible: 4,
                    avatarSize: 32,
                  ),
                  const Gap(12),
                ] else
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.people_alt_outlined,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    state.selectedFriendIds.isEmpty
                        ? 'No friends selected'
                        : '${state.selectedFriendIds.length} friend(s) selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed:
                      () async => await showCreatePackFriendPicker(context),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
