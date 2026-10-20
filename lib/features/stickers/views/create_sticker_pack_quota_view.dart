import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class CreateStickerPackQuotaView extends StatelessWidget {
  final CreateStickerPackQuotaBlocked state;
  const CreateStickerPackQuotaView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(context.l10n.youAlreadyOwn3, textAlign: TextAlign.center),
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
                  subtitle: Text(context.l10n.stickers2(pack.stickerCount)),
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
