import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_cubit.dart';
import '../cubit/sticker_pack_detail_cubit/sticker_pack_detail_state.dart';
import '../model/sticker_pack_model.dart';
import '../widgets/sticker_thumbnail.dart';

class StickerPackDetailView extends StatelessWidget {
  final StickerPackModel pack;
  const StickerPackDetailView({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StickerPackDetailCubit(packId: pack.id),
      child: _StickerPackDetailSheetBody(pack: pack),
    );
  }
}

class _StickerPackDetailSheetBody extends StatefulWidget {
  final StickerPackModel pack;
  const _StickerPackDetailSheetBody({required this.pack});

  @override
  State<_StickerPackDetailSheetBody> createState() =>
      _StickerPackDetailSheetBodyState();
}

class _StickerPackDetailSheetBodyState
    extends State<_StickerPackDetailSheetBody> {
  bool _isProcessing = false;

  void _handleToggleDownload(bool isDownloaded) async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    context.read<StickerPackDetailCubit>().toggleDownloaded();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.pack.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.pack.stickerCount} Stickers',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<StickerPackDetailCubit, StickerPackDetailState>(
        builder: (context, state) {
          if (state is StickerPackDetailLoading) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (state is StickerPackDetailError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as StickerPackDetailLoaded;
          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: loaded.stickers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final sticker = loaded.stickers[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: StickerThumbnail(sticker: sticker),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBottomActionBar(theme, loaded.isDownloaded),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(ThemeData theme, bool isDownloaded) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            _isProcessing
                ? SizedBox(
                  height: 56,
                  child: Center(
                    child: CustomLoadingIndicator(color: theme.primaryColor),
                  ),
                )
                : FilledButton.icon(
                  key: ValueKey(isDownloaded),
                  onPressed: () => _handleToggleDownload(isDownloaded),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor:
                        isDownloaded
                            ? theme.colorScheme.errorContainer
                            : theme.primaryColor,
                    foregroundColor:
                        isDownloaded
                            ? theme.colorScheme.onErrorContainer
                            : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: isDownloaded ? 0 : 2,
                  ),
                  icon: Icon(
                    isDownloaded
                        ? Icons.delete_outline_rounded
                        : Icons.download_rounded,
                    size: 24,
                  ),
                  label: Text(
                    isDownloaded ? 'Remove from Library' : 'Download Pack',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
      ),
    );
  }
}
