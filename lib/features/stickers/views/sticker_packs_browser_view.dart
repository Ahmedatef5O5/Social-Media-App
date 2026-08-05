import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../cubit/sticker_packs_cubit/sticker_packs_cubit.dart';
import '../cubit/sticker_packs_cubit/sticker_packs_state.dart';
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
      appBar: AppBar(
        title: const Text(
          'Sticker Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Create Pack',
            icon: const Icon(Icons.add_rounded),
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
        ],
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
                    () => context.read<StickerPacksCubit>().cancelDownload(
                      pack.id,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
