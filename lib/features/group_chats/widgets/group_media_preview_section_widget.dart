import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/router/app_routes.dart';
import '../cubit/group_media_cubit/group_media_cubit.dart';
import '../models/groupe_message_model.dart';
import '../views/group_media_view.dart';

class GroupMediaPreviewSection extends StatelessWidget {
  final GroupMediaCubit mediaCubit;
  final String groupId;

  const GroupMediaPreviewSection({
    super.key,
    required this.mediaCubit,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BlocBuilder<GroupMediaCubit, GroupMediaState>(
        bloc: mediaCubit..loadPreview(),
        builder: (context, state) {
          if (!state.previewLoading && state.preview.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Media, links, and docs',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => GroupMediaView(
                                    mediaCubit: mediaCubit,
                                    groupId: groupId,
                                  ),
                            ),
                          ),
                      child: Text(
                        'See all',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                if (state.previewLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.preview.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemBuilder:
                        (context, index) =>
                            _MediaPreviewTile(message: state.preview[index]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MediaPreviewTile extends StatelessWidget {
  final GroupMessageModel message;
  const _MediaPreviewTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _openMedia(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: switch (message.messageType) {
          'image' => CachedNetworkImage(
            imageUrl: message.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
          'video' => Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: message.videoUrl ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.black26),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          _ => Container(
            color: primary.withValues(alpha: 0.12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: primary),
                const Gap(4),
                Text('Voice', style: TextStyle(color: primary, fontSize: 11)),
              ],
            ),
          ),
        },
      ),
    );
  }

  void _openMedia(BuildContext context) {
    if (message.messageType == 'image' && message.imageUrl != null) {
      Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.fullScreenImageViewRoute,
        arguments: {
          'url': message.imageUrl!,
          'tag': 'media-${message.id}',
          'isAsset': false,
        },
      );
    }
  }
}
