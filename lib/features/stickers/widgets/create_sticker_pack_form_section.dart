import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import 'create_sticker_pack_action_button.dart';
import 'create_sticker_pack_privacy_section.dart';
import 'create_sticker_pack_stickers_section.dart';
import 'create_sticker_pack_title_field.dart';

class CreateStickerPackFormSection extends StatelessWidget {
  final CreateStickerPackForm state;
  const CreateStickerPackFormSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CreateStickerPackCubit>();
    final sizeMb = (state.totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);

    final selectedFriends =
        state.allFriends
            .where((f) => state.selectedFriendIds.contains(f.user.id))
            .toList();
    final avatars = selectedFriends.map((f) => f.user.imageUrl ?? '').toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              CreateStickerPackTitleField(cubit: cubit, theme: theme),
              const Gap(24),

              CreateStickerPackStickersSection(
                theme: theme,
                state: state,
                sizeMb: sizeMb,
                cubit: cubit,
              ),

              CreateStickerPackPrivacySection(
                theme: theme,
                state: state,
                cubit: cubit,
                avatars: avatars,
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
          child: CreateStickerPackActionButton(
            isUploading: false,
            progress: 0,
            canSubmit: state.canSubmit,
            onSubmit: cubit.submit,
          ),
        ),
      ],
    );
  }
}
