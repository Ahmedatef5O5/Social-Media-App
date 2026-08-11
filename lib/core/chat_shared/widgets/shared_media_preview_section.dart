import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../helpers/shared_media_preview_skeleton.dart';
import '../views/shared_media_view.dart';
import 'media_preview_tile.dart';

class SharedMediaPreviewSection extends StatelessWidget {
  final SharedMediaCubit mediaCubit;
  final ShowInChatCallback? onShowInChat;

  const SharedMediaPreviewSection({
    super.key,
    required this.mediaCubit,
    this.onShowInChat,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedMediaCubit, SharedMediaState>(
      bloc:
          mediaCubit
            ..loadPreview()
            ..loadTab(SharedMediaTab.all),
      builder: (context, state) {
        if (!state.previewLoading && state.preview.isEmpty) {
          return const SizedBox.shrink();
        }

        final fullList = state.itemsFor(SharedMediaTab.all);
        final allItems = fullList.isNotEmpty ? fullList : state.preview;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Media, links, and docs',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => SharedMediaView(
                                  mediaCubit: mediaCubit,
                                  onShowInChat: onShowInChat,
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
                const SharedMediaPreviewSkeleton()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.preview.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder:
                      (context, index) => MediaPreviewTile(
                        item: state.preview[index],
                        items: allItems,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}
