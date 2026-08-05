import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import '../../../core/toast/app_toast.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import '../widgets/create_sticker_pack_form_section.dart';
import 'create_sticker_pack_quota_view.dart';
import 'create_sticker_pack_uploading_view.dart';

class CreateStickerPackView extends StatelessWidget {
  const CreateStickerPackView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => CreateStickerPackCubit(
            mediaCacheRepository: context.read<MediaCacheRepository>(),
          ),
      child: const _CreateStickerPackBody(),
    );
  }
}

class _CreateStickerPackBody extends StatelessWidget {
  const _CreateStickerPackBody();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Create Sticker Pack',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
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
              switch (state) {
                case CreateStickerPackLoading():
                case CreateStickerPackSuccess():
                  return const Center(child: CustomLoadingIndicator());

                case CreateStickerPackError():
                  return Center(child: Text(state.message));

                case CreateStickerPackQuotaBlocked():
                  return CreateStickerPackQuotaView(state: state);

                case CreateStickerPackUploading():
                  return CreateStickerPackUploadingView(state: state);

                case CreateStickerPackForm():
                  return CreateStickerPackFormSection(state: state);
                default:
                  return CustomLoadingIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
