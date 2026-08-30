import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import '../models/sticker_pack_privacy.dart';
import '../widgets/cancel_progress_bubble.dart';
import '../widgets/create_sticker_pack_action_button.dart';
import '../widgets/sticker_grid_item.dart';

class CreateStickerPackUploadingView extends StatelessWidget {
  final CreateStickerPackUploading state;
  const CreateStickerPackUploadingView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uploadedMb = state.uploadedBytes / (1024 * 1024);
    final totalMb = state.totalBytes / (1024 * 1024);
    final label =
        '${uploadedMb.toStringAsFixed(1)}/${totalMb.toStringAsFixed(1)} MB  •  ${state.doneCount}/${state.images.length}';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              TextField(
                enabled: false,
                controller: TextEditingController(text: state.title),
                decoration: const InputDecoration(
                  labelText: 'Pack Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(20),
              Text(
                'Uploading  •  $label',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.grey6,
                ),
              ),
              const Gap(10),
              StickerGridItem(
                images: state.images,
                completedFlags: state.completedFlags,
              ),
              const Gap(24),
              Text(
                'Privacy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(10),
              IgnorePointer(
                child: Opacity(
                  opacity: 0.5,
                  child: SegmentedButton<StickerPackPrivacy>(
                    segments:
                        StickerPackPrivacy.values
                            .map(
                              (p) =>
                                  ButtonSegment(value: p, label: Text(p.label)),
                            )
                            .toList(),
                    selected: {state.privacy},
                    onSelectionChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  state.overallProgress < 1.0
                      ? CancelProgressBubble(
                        size: 18,
                        visible: state.overallProgress < 1.0,
                        onCancel:
                            () =>
                                context
                                    .read<CreateStickerPackCubit>()
                                    .cancelUpload(),
                      )
                      : const SizedBox.shrink(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.grey6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              CreateStickerPackActionButton(
                isUploading: true,
                progress: state.overallProgress,
                canSubmit: false,
                onSubmit: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
