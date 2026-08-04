import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/toast/app_toast.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import '../model/sticker_pack_privacy.dart';
import '../widgets/friend_picker_sheet.dart';

class CreateStickerPackView extends StatelessWidget {
  const CreateStickerPackView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateStickerPackCubit(),
      child: const _CreateStickerPackBody(),
    );
  }
}

class _CreateStickerPackBody extends StatelessWidget {
  const _CreateStickerPackBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sticker Pack'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocListener<CreateStickerPackCubit, CreateStickerPackState>(
        listener: (context, state) {
          if (state is CreateStickerPackSuccess) {
            AppToast.success('Pack "${state.pack.title}" created!');
            Navigator.of(context).pop(state.pack);
          }
        },

        child: BlocBuilder<CreateStickerPackCubit, CreateStickerPackState>(
          builder: (context, state) {
            if (state is CreateStickerPackLoading) {
              return const Center(child: CustomLoadingIndicator());
            }
            if (state is CreateStickerPackError) {
              return Center(child: Text(state.message));
            }
            if (state is CreateStickerPackQuotaBlocked) {
              return _QuotaBlockedView(state: state);
            }
            if (state is CreateStickerPackUploading) {
              return _UploadingView(state: state);
            }
            if (state is CreateStickerPackSuccess) {
              return const Center(child: CustomLoadingIndicator());
            }

            return _FormView(state: state as CreateStickerPackForm);
          },
        ),
      ),
    );
  }
}

class _QuotaBlockedView extends StatelessWidget {
  final CreateStickerPackQuotaBlocked state;
  const _QuotaBlockedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'You already own 3 sticker packs — the maximum allowed. '
            'Remove one below to create a new pack.',
            textAlign: TextAlign.center,
          ),
        ),
        const Gap(16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.myPacks.length,
            itemBuilder: (context, index) {
              final pack = state.myPacks[index];
              return Card(
                child: ListTile(
                  title: Text(pack.title),
                  subtitle: Text('${pack.stickerCount} stickers'),
                  trailing:
                      state.isDeleting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: Theme.of(context).colorScheme.error,
                            onPressed:
                                () => context
                                    .read<CreateStickerPackCubit>()
                                    .deleteAndRetry(pack.id),
                          ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FormView extends StatelessWidget {
  final CreateStickerPackForm state;
  const _FormView({required this.state});

  void _openFriendPicker(BuildContext context) {
    final cubit = context.read<CreateStickerPackCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => BlocBuilder<CreateStickerPackCubit, CreateStickerPackState>(
            bloc: cubit,
            builder: (context, latest) {
              final form = latest as CreateStickerPackForm;
              return FriendPickerSheet(
                friends: form.allFriends,
                selectedIds: form.selectedFriendIds,
                onToggle: cubit.toggleFriend,
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CreateStickerPackCubit>();
    final sizeMb = (state.totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: cubit.setTitle,
                decoration: const InputDecoration(
                  labelText: 'Pack Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(20),
              Text(
                'Stickers  •  ${state.images.length}/${CreateStickerPackForm.maxStickers}  •  $sizeMb/25 MB',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.grey6,
                ),
              ),
              const Gap(10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.images.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  if (index == state.images.length) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: cubit.pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    );
                  }
                  final image = state.images[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(image.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => cubit.removeImage(index),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Gap(24),
              Text(
                'Privacy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(10),
              SegmentedButton<StickerPackPrivacy>(
                segments:
                    StickerPackPrivacy.values
                        .map(
                          (p) => ButtonSegment(value: p, label: Text(p.label)),
                        )
                        .toList(),
                selected: {state.privacy},
                onSelectionChanged:
                    (selection) => cubit.setPrivacy(selection.first),
              ),
              if (state.privacy == StickerPackPrivacy.friends) ...[
                const Gap(10),
                OutlinedButton.icon(
                  onPressed: () => _openFriendPicker(context),
                  icon: const Icon(Icons.people_outline_rounded),
                  label: Text(
                    state.selectedFriendIds.isEmpty
                        ? 'Choose Friends'
                        : '${state.selectedFriendIds.length} friend(s) selected',
                  ),
                ),
              ],
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
          child: FilledButton(
            onPressed: state.canSubmit ? cubit.submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child:
                state.isSubmitting
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Create Pack'),
          ),
        ),
      ],
    );
  }
}

class _UploadingView extends StatelessWidget {
  final CreateStickerPackUploading state;
  const _UploadingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.total == 0 ? 0.0 : state.done / state.total;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress),
            const Gap(16),
            Text('Uploading stickers… ${state.done}/${state.total}'),
          ],
        ),
      ),
    );
  }
}
