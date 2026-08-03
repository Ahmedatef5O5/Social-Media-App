import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../views/shared_media_view.dart';
import 'media_preview_tile.dart';

class SharedMediaPreviewSection extends StatelessWidget {
  final SharedMediaCubit mediaCubit;

  const SharedMediaPreviewSection({super.key, required this.mediaCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedMediaCubit, SharedMediaState>(
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
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => SharedMediaView(mediaCubit: mediaCubit),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder:
                      (context, index) =>
                          MediaPreviewTile(item: state.preview[index]),
                ),
            ],
          ),
        );
      },
    );
  }
}
