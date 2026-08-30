import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/sticker_send_picker_cubit/sticker_send_picker_cubit.dart';
import '../cubits/sticker_send_picker_cubit/sticker_send_picker_state.dart';
import '../views/empty_downloads_sheet_view.dart';
import '../views/sticker_packs_browser_view.dart';
import 'sticker_thumbnail.dart';

class StickerSendPickerSheet extends StatelessWidget {
  const StickerSendPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StickerSendPickerCubit(),
      child: const _StickerSendPickerSheetBody(),
    );
  }
}

class _StickerSendPickerSheetBody extends StatelessWidget {
  const _StickerSendPickerSheetBody();

  void _openBrowser(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StickerPacksBrowserView()));
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
                    return EmptyDownloadsSheetView(
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
                                          () => Navigator.of(
                                            context,
                                          ).pop(sticker),
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
