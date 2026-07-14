import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/comments/model/comment_attachment_draft.dart';
import 'package:social_media_app/features/comments/model/comment_type.dart';
import 'package:social_media_app/features/stickers/cubit/sticker_send_picker_cubit/sticker_send_picker_cubit.dart';
import 'package:social_media_app/features/stickers/cubit/sticker_send_picker_cubit/sticker_send_picker_state.dart';
import '../../stickers/widgets/sticker_packs_browser_sheet.dart';
import '../../stickers/widgets/sticker_thumbnail.dart';

class CommentStickerPickerSheet extends StatelessWidget {
  const CommentStickerPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StickerSendPickerCubit(),
      child: const _CommentStickerPickerSheetBody(),
    );
  }
}

class _CommentStickerPickerSheetBody extends StatelessWidget {
  const _CommentStickerPickerSheetBody();

  void _openBrowser(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StickerPacksBrowserSheet()));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey5.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: BlocBuilder<
                StickerSendPickerCubit,
                StickerSendPickerState
              >(
                builder: (context, state) {
                  if (state is StickerSendPickerLoading) {
                    return const Center(child: CustomLoadingIndicator());
                  }
                  if (state is StickerSendPickerError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is StickerSendPickerEmpty) {
                    return _EmptyDownloadsView(
                      onBrowse: () => _openBrowser(context),
                    );
                  }

                  final loaded = state as StickerSendPickerLoaded;
                  return Column(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: loaded.downloadedPacks.length,
                                separatorBuilder: (_, __) => const Gap(10),
                                itemBuilder: (context, index) {
                                  final pack = loaded.downloadedPacks[index];
                                  final isSelected =
                                      index == loaded.selectedIndex;
                                  return ChoiceChip(
                                    label: Text(pack.title),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    labelStyle: TextStyle(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                    ),
                                    selectedColor: theme.primaryColor,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? theme.primaryColor
                                                : Colors.transparent,
                                      ),
                                    ),
                                    onSelected:
                                        (_) => context
                                            .read<StickerSendPickerCubit>()
                                            .selectPack(index),
                                  );
                                },
                              ),
                            ),
                            const Gap(8),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                tooltip: 'Browse Library',
                                icon: Icon(
                                  Icons.add_rounded,
                                  color: theme.primaryColor,
                                ),
                                onPressed: () => _openBrowser(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child:
                            loaded.isLoadingSelectedPack
                                ? const Center(child: CustomLoadingIndicator())
                                : GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: loaded.selectedStickers.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                      ),
                                  itemBuilder: (context, index) {
                                    final sticker =
                                        loaded.selectedStickers[index];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap:
                                          () => Navigator.of(context).pop(
                                            CommentAttachmentDraft(
                                              type: CommentType.sticker,
                                              remoteUrl: sticker.imageUrl,
                                            ),
                                          ),
                                      child: StickerThumbnail(sticker: sticker),
                                    );
                                  },
                                ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDownloadsView extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyDownloadsView({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_mosaic_rounded,
                size: 56,
                color: theme.primaryColor,
              ),
            ),
            const Gap(24),

            Text(
              'No Stickers Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Gap(10),

            Text(
              'Discover and download amazing sticker packs from the library to express yourself.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey6,
                height: 1.4,
              ),
            ),
            const Gap(32),

            FilledButton.icon(
              onPressed: onBrowse,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.storefront_rounded, size: 22),
              label: const Text(
                'Explore Library',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
