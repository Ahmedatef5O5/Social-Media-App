import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import 'sticker_grid_item.dart';

class CreateStickerPackStickersSection extends StatelessWidget {
  final ThemeData theme;
  final CreateStickerPackForm state;
  final String sizeMb;
  final CreateStickerPackCubit cubit;

  const CreateStickerPackStickersSection({
    super.key,
    required this.theme,
    required this.state,
    required this.sizeMb,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stickers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${state.images.length}/${CreateStickerPackForm.maxStickers}  •  $sizeMb/25 MB',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.grey6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Gap(12),
        StickerGridItem(
          images: state.images,
          onAddTap: cubit.pickImages,
          onRemove: cubit.removeImage,
          onImageTap: (index, path) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FullScreenImageViewer(),
                settings: RouteSettings(
                  arguments: {
                    'url': path,
                    'isLocalFile': true,
                    'tag': 'create_sticker_$index',
                  },
                ),
              ),
            );
          },
        ),
        const Gap(32),
      ],
    );
  }
}
