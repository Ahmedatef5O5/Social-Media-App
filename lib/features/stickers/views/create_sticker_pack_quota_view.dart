import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubits/create_sticker_pack_cubit/create_sticker_pack_state.dart';

class CreateStickerPackQuotaView extends StatelessWidget {
  final CreateStickerPackQuotaBlocked state;
  const CreateStickerPackQuotaView({super.key, required this.state});

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
