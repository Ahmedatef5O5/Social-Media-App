import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_cubit.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_state.dart';
import '../model/sticker_pack_model.dart';
import '../utils/byte_size_utils.dart';
import '../widgets/create_pack_bottom_action_bar.dart';
import '../widgets/sticker_pack_detail_grid.dart';

class StickerPackDetailView extends StatelessWidget {
  final StickerPackModel pack;
  const StickerPackDetailView({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => StickerPackDetailCubit(
            packId: pack.id,
            mediaCacheRepository: context.read<MediaCacheRepository>(),
          ),
      child: _StickerPackDetailSheetBody(pack: pack),
    );
  }
}

class _StickerPackDetailSheetBody extends StatelessWidget {
  final StickerPackModel pack;
  const _StickerPackDetailSheetBody({required this.pack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              pack.title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              pack.totalSizeBytes > 0
                  ? '${pack.stickerCount} Stickers  •  ${pack.totalSizeBytes.asReadableSize}'
                  : '${pack.stickerCount} Stickers',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<StickerPackDetailCubit, StickerPackDetailState>(
        builder: (context, state) {
          if (state is StickerPackDetailLoading) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (state is StickerPackDetailError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as StickerPackDetailLoaded;
          return Column(
            children: [
              StickerPackDetailGrid(loaded: loaded, theme: theme),
              CreatePackBottomActionBar(
                pack: pack,
                context: context,
                theme: theme,
                loaded: loaded,
              ),
            ],
          );
        },
      ),
    );
  }
}
