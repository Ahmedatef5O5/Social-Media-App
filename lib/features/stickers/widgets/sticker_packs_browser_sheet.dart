import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../cubit/sticker_packs_cubit/sticker_packs_cubit.dart';
import '../cubit/sticker_packs_cubit/sticker_packs_state.dart';
import '../model/sticker_pack_model.dart';
import 'sticker_pack_details_sheet.dart';

class StickerPacksBrowserSheet extends StatelessWidget {
  const StickerPacksBrowserSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StickerPacksCubit(),
      child: const _StickerPacksBrowserSheetBody(),
    );
  }
}

class _StickerPacksBrowserSheetBody extends StatelessWidget {
  const _StickerPacksBrowserSheetBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sticker Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<StickerPacksCubit, StickerPacksState>(
        builder: (context, state) {
          if (state is StickerPacksLoading) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (state is StickerPacksError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as StickerPacksLoaded;
          if (loaded.packs.isEmpty) {
            return const Center(
              child: Text('There are no packages available yet.'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loaded.packs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final pack = loaded.packs[index];
              final isDownloaded = loaded.downloadedPackIds.contains(pack.id);

              return _PackCard(
                pack: pack,
                isDownloaded: isDownloaded,
                onTap: () async {
                  final cubit = context.read<StickerPacksCubit>();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StickerPackDetailSheet(pack: pack),
                    ),
                  );
                  cubit.loadPacks();
                },
                onToggleDownload: () {
                  context.read<StickerPacksCubit>().togglePackDownloaded(
                    pack.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PackCard extends StatefulWidget {
  final StickerPackModel pack;
  final bool isDownloaded;
  final VoidCallback onTap;
  final VoidCallback onToggleDownload;

  const _PackCard({
    required this.pack,
    required this.isDownloaded,
    required this.onTap,
    required this.onToggleDownload,
  });

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard> {
  bool _isProcessing = false;

  void _handleAction() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    widget.onToggleDownload();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                widget.isDownloaded
                    ? theme.primaryColor.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedCloudinaryImage(
                    secureUrl: widget.pack.coverUrl,
                    fit: BoxFit.contain,
                    placeholder: (context) => const CustomLoadingIndicator(),
                    errorWidget:
                        (context, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.2),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.pack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(4),
            Text(
              '${widget.pack.stickerCount} stickers',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey6,
              ),
            ),
            const Gap(10),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _isProcessing
                        ? SizedBox(
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        )
                        : FilledButton.tonal(
                          key: ValueKey(widget.isDownloaded),
                          onPressed: _handleAction,
                          style: FilledButton.styleFrom(
                            minimumSize: Size(double.infinity, 36),
                            backgroundColor:
                                widget.isDownloaded
                                    ? theme.colorScheme.errorContainer
                                    : theme.primaryColor.withValues(
                                      alpha: 0.15,
                                    ),
                            foregroundColor:
                                widget.isDownloaded
                                    ? theme.colorScheme.onErrorContainer
                                    : theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          child: Text(
                            widget.isDownloaded ? 'Remove' : 'Download',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
