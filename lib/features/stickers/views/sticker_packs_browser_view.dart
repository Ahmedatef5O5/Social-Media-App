import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../cubits/sticker_packs_cubit/sticker_packs_cubit.dart';
import '../cubits/sticker_packs_cubit/sticker_packs_state.dart';
import '../widgets/sticker_pack_card.dart';
import 'create_sticker_pack_view.dart';
import 'sticker_pack_details_view.dart';

class StickerPacksBrowserView extends StatelessWidget {
  const StickerPacksBrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => StickerPacksCubit(
            mediaCacheRepository: context.read<MediaCacheRepository>(),
          ),
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
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Sticker Library',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            titleSpacing: 0,
            centerTitle: false,
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.95,
            ),
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Create Pack',
                icon: Image.asset(
                  AppImages.addStickerPackIcon,
                  height: 28,
                  width: 28,
                  fit: BoxFit.contain,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ),
                onPressed: () async {
                  final cubit = context.read<StickerPacksCubit>();
                  final created = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateStickerPackView(),
                    ),
                  );
                  if (created != null) cubit.loadPacks();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          BlocBuilder<StickerPacksCubit, StickerPacksState>(
            builder: (context, state) {
              if (state is StickerPacksLoading) {
                return const _StickerSkeletonGrid();
              }

              if (state is StickerPacksError) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                );
              }

              final loaded = state as StickerPacksLoaded;
              final packs = loaded.packs;

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == packs.length) {
                      return const _CreateStickerPackCard();
                    }

                    final pack = packs[index];
                    final isDownloaded = loaded.downloadedPackIds.contains(
                      pack.id,
                    );
                    final progress = loaded.downloadProgress[pack.id];

                    return StickerPackCard(
                      pack: pack,
                      isDownloaded: isDownloaded,
                      progress: progress,
                      onTap: () async {
                        final cubit = context.read<StickerPacksCubit>();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StickerPackDetailView(pack: pack),
                          ),
                        );
                        cubit.loadPacks();
                      },
                      onToggleDownload:
                          () => context
                              .read<StickerPacksCubit>()
                              .togglePackDownloaded(pack.id),
                      onCancelDownload:
                          () => context
                              .read<StickerPacksCubit>()
                              .cancelDownload(pack.id),
                    );
                  }, childCount: packs.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StickerSkeletonGrid extends StatelessWidget {
  const _StickerSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Gap(6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreateStickerPackCard extends StatelessWidget {
  const _CreateStickerPackCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final cubit = context.read<StickerPacksCubit>();
        final created = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateStickerPackView()),
        );
        if (created != null) cubit.loadPacks();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.5),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 54,
              color: theme.primaryColor,
            ),
            const Gap(16),
            Text(
              'Create Your Own\nSticker Pack',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
