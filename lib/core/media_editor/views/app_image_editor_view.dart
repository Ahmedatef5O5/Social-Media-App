import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/media_editor/media_editor_models.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/gifs/models/gif_result_model.dart';
import 'package:social_media_app/features/gifs/widgets/gif_picker_sheet.dart';
import 'package:social_media_app/features/stickers/models/sticker_model.dart';
import 'package:social_media_app/features/stickers/utils/sticker_url_utils.dart';
import 'package:social_media_app/features/stickers/widgets/sticker_send_picker_sheet.dart';

/// Full-screen image editor (crop / rotate / flip, draw, text, filters, blur &
/// pixelate, emoji) built on `pro_image_editor`, plus Sticker and GIF layers
/// powered by the app's EXISTING pickers.

class AppImageEditorView extends StatefulWidget {
  const AppImageEditorView({
    super.key,
    required this.file,
    this.preset = MediaEditorPreset.free,
  });

  final File file;
  final MediaEditorPreset preset;

  @override
  State<AppImageEditorView> createState() => _AppImageEditorViewState();
}

class _AppImageEditorViewState extends State<AppImageEditorView> {
  final GlobalKey<ProImageEditorState> _editorKey =
      GlobalKey<ProImageEditorState>();

  bool get _isPng => widget.file.path.toLowerCase().endsWith('.png');

  // ── Existing Sticker / GIF sheets → movable, resizable canvas layers ─────

  Future<void> _pickSticker() async {
    HapticFeedback.selectionClick();
    final sticker = await showModalBottomSheet<StickerModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StickerSendPickerSheet(),
    );
    if (sticker == null || !mounted) return;
    _addImageLayer(
      StickerUrlUtils.staticPreviewUrl(
        sticker.imageUrl,
        isAnimated: sticker.isAnimated,
      ),
      width: 140,
    );
  }

  Future<void> _pickGif() async {
    HapticFeedback.selectionClick();
    final gif = await showModalBottomSheet<GifResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GifPickerSheet(),
    );
    if (gif == null || !mounted) return;
    _addImageLayer(gif.sendUrl, width: 180);
  }

  void _addImageLayer(String url, {required double width}) {
    final editor = _editorKey.currentState;
    if (editor == null) return;
    HapticFeedback.mediumImpact();
    editor.addLayer(
      WidgetLayer(
        widget: SizedBox(
          width: width,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder:
                (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.white70,
                  size: 48,
                ),
          ),
        ),
      ),
    );
  }

  // ── Configs ───────────────────────────────────────────────────────────────

  CropRotateEditorConfigs _cropConfigs() {
    switch (widget.preset) {
      case MediaEditorPreset.avatar:
        return CropRotateEditorConfigs(
          aspectRatios: [AspectRatioItem(text: '1:1', value: 1.0)],
          initAspectRatio: 1.0,
          initialCropMode: CropMode.oval,
          // Keep the exported file rectangular; the app clips it to a circle.
          exportOvalMask: false,
        );
      case MediaEditorPreset.cover:
        return CropRotateEditorConfigs(
          aspectRatios: [
            AspectRatioItem(text: '16:9', value: 16 / 9),
            AspectRatioItem(text: '2:1', value: 2 / 1),
            AspectRatioItem(text: '3:1', value: 3 / 1),
          ],
          initAspectRatio: 16 / 9,
        );
      default:
        return CropRotateEditorConfigs(
          aspectRatios: [
            AspectRatioItem(text: 'Free', value: null),
            AspectRatioItem(text: '1:1', value: 1.0),
            AspectRatioItem(text: '4:5', value: 4 / 5),
            AspectRatioItem(text: '16:9', value: 16 / 9),
            AspectRatioItem(text: '9:16', value: 9 / 16),
          ],
        );
    }
  }

  ProImageEditorConfigs _configs() {
    return ProImageEditorConfigs(
      // Keep transparent PNGs transparent; everything else stays JPEG.
      imageGeneration:
          _isPng
              ? ImageGenerationConfigs(outputFormat: OutputFormat.png)
              : const ImageGenerationConfigs(),
      cropRotateEditor: _cropConfigs(),
      textEditor: TextEditorConfigs(
        customTextStyles: const [
          TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: AppTypography.fontFallback,
            fontWeight: FontWeight.w600,
          ),
          TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: AppTypography.fontFallback,
            fontWeight: FontWeight.w700,
          ),
          TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontFamilyFallback: AppTypography.fontFallback,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  ThemeData _editorTheme(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        brightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Theme(
      data: _editorTheme(context),
      child: Stack(
        children: [
          Positioned.fill(
            child: ProImageEditor.file(
              widget.file,
              key: _editorKey,
              callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (Uint8List bytes) async {
                  HapticFeedback.lightImpact();
                  if (mounted) Navigator.of(context).pop(bytes);
                },
                mainEditorCallbacks: MainEditorCallbacks(
                  helperLines: HelperLinesCallbacks(
                    onLineHit: HapticFeedback.selectionClick,
                  ),
                ),
              ),
              configs: _configs(),
            ),
          ),

          // Sticker / GIF launchers. They live on the main canvas only —
          // sub-editors (draw, text, crop…) are separate pages and cover them.
          Positioned(
            top: topInset + 64,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LauncherButton(
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Sticker',
                    onTap: _pickSticker,
                  ),
                  const SizedBox(height: 10),
                  _LauncherButton(
                    icon: Icons.gif_box_outlined,
                    label: 'GIF',
                    onTap: _pickGif,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LauncherButton extends StatelessWidget {
  const _LauncherButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white24, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
