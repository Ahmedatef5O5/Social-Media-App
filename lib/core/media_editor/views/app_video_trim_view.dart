import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/media_editor/media_editor_models.dart';
import 'package:social_media_app/core/media_editor/services/video_trimmer.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

/// Timeline trimmer (WhatsApp / Instagram-Stories style): thumbnail strip with
/// two drag handles, live looping preview of the selected window, and a
/// "selected / total" readout.
///
/// Pops with a [TrimmedVideo] on Done, or `null` if cancelled / unchanged.
class AppVideoTrimView extends StatefulWidget {
  const AppVideoTrimView({super.key, required this.file, this.maxDuration});

  final File file;

  /// Longest selectable window (e.g. story limit). `null` = unlimited.
  final Duration? maxDuration;

  @override
  State<AppVideoTrimView> createState() => _AppVideoTrimViewState();
}

class _AppVideoTrimViewState extends State<AppVideoTrimView> {
  static const int _thumbCount = 10;
  static const double _handleWidth = 14;
  static const double _stripHeight = 56;

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _loadFailed = false;
  bool _exporting = false;

  double _totalMs = 0;
  double _minMs = 1000;
  double _maxMs = 0;
  RangeValues _range = const RangeValues(0, 0);

  final List<Uint8List?> _thumbs = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.file(widget.file);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      _totalMs = c.value.duration.inMilliseconds.toDouble();
      _minMs = math.min(
        MediaEditorLimits.minTrimDuration.inMilliseconds.toDouble(),
        _totalMs,
      );
      final limit = widget.maxDuration?.inMilliseconds.toDouble();
      _maxMs = limit == null ? _totalMs : math.min(limit, _totalMs);
      _range = RangeValues(0, _maxMs);

      await c.setLooping(false);
      c.addListener(_onTick);
      _controller = c;
      setState(() => _ready = true);
      c.play();
      _loadThumbnails();
    } catch (e) {
      debugPrint('[AppVideoTrimView] init failed: $e');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _loadThumbnails() async {
    for (var i = 0; i < _thumbCount; i++) {
      if (!mounted) return;
      Uint8List? data;
      try {
        data = await VideoThumbnail.thumbnailData(
          video: widget.file.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: (_totalMs * i / _thumbCount).round(),
          maxWidth: 160,
          quality: 60,
        );
      } catch (_) {
        data = null;
      }
      if (!mounted) return;
      setState(() => _thumbs.add(data));
    }
  }

  /// Loops the selected window and keeps the playhead UI in sync.
  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    final pos = c.value.position.inMilliseconds.toDouble();
    if (c.value.isPlaying && pos >= _range.end) {
      c.seekTo(Duration(milliseconds: _range.start.round()));
    }
    setState(() {});
  }

  void _onRangeChanged(RangeValues v) {
    var start = v.start;
    var end = v.end;
    final movedStart = (start - _range.start).abs() > (end - _range.end).abs();

    if (end - start < _minMs) {
      if (movedStart) {
        start = end - _minMs;
      } else {
        end = start + _minMs;
      }
    }
    if (end - start > _maxMs) {
      if (movedStart) {
        end = start + _maxMs;
      } else {
        start = end - _maxMs;
      }
    }
    start = start.clamp(0.0, _totalMs);
    end = end.clamp(0.0, _totalMs);

    setState(() => _range = RangeValues(start, end));
    final seekTo = movedStart ? start : math.max(start, end - 800);
    _controller?.seekTo(Duration(milliseconds: seekTo.round()));
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    HapticFeedback.selectionClick();
    if (c.value.isPlaying) {
      c.pause();
    } else {
      final pos = c.value.position.inMilliseconds;
      if (pos < _range.start || pos >= _range.end) {
        c.seekTo(Duration(milliseconds: _range.start.round()));
      }
      c.play();
    }
  }

  bool get _unchanged => _range.start <= 0 && _range.end >= _totalMs - 50;

  Future<void> _done() async {
    if (_exporting) return;
    if (_unchanged) {
      Navigator.of(context).pop();
      return;
    }
    HapticFeedback.lightImpact();
    _controller?.pause();
    setState(() => _exporting = true);

    final startMs = _range.start.round();
    final endMs = _range.end.round();
    try {
      final out = await VideoTrimmer.trim(
        source: widget.file,
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: endMs),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        TrimmedVideo(
          file: out,
          duration: Duration(milliseconds: endMs - startMs),
        ),
      );
    } catch (e) {
      debugPrint('[AppVideoTrimView] trim failed: $e');
      AppToast.error(context.l10n.couldNotTrimThis);
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fmt(double ms) {
    final d = Duration(milliseconds: ms.round());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return PopScope(
      canPop: !_exporting,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.white),
            onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          ),
          title: Text(
            context.l10n.trimVideo,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: context.l10n.done,
                icon: Icon(
                  Icons.check_circle_rounded,
                  color: primary,
                  size: 30,
                ),
                onPressed: (_ready && !_exporting) ? _done : null,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(primary),
            if (_exporting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomLoadingIndicator(color: AppColors.white),
                      SizedBox(height: 14),
                      Text(
                        context.l10n.trimming,
                        style: TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color primary) {
    if (_loadFailed) {
      return Center(
        child: Text(
          context.l10n.couldNotLoadThis,
          style: TextStyle(color: AppColors.white70),
        ),
      );
    }
    if (!_ready || _controller == null) {
      return const Center(
        child: CustomLoadingIndicator(color: AppColors.white),
      );
    }

    final c = _controller!;
    final selectedMs = _range.end - _range.start;
    final overLimit = widget.maxDuration != null && _totalMs > _maxMs;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                    AnimatedOpacity(
                      opacity: c.value.isPlaying ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.selected2(_fmt(selectedMs)),
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.total(_fmt(_totalMs)),
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (overLimit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.maxLengthIs(_fmt(_maxMs)),
                  style: const TextStyle(
                    color: AppColors.goldenYellow,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: _buildTrimBar(primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimBar(Color primary) {
    final canTrim = _totalMs > _minMs;
    final total = math.max(_totalMs, 1.0);

    return SizedBox(
      height: _stripHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final trackW = box.maxWidth - _handleWidth;
          final leftPx = _handleWidth / 2 + trackW * (_range.start / total);
          final rightPx = _handleWidth / 2 + trackW * (_range.end / total);

          return Stack(
            children: [
              // Thumbnails
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _handleWidth / 2,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: List.generate(_thumbCount, (i) {
                        final data = i < _thumbs.length ? _thumbs[i] : null;
                        return Expanded(
                          child:
                              data == null
                                  ? Container(color: AppColors.grey9)
                                  : Image.memory(
                                    data,
                                    fit: BoxFit.cover,
                                    height: _stripHeight,
                                    gaplessPlayback: true,
                                  ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // Dim everything outside the selection
              Positioned(
                left: _handleWidth / 2,
                width: math.max(0, leftPx - _handleWidth / 2),
                top: 0,
                bottom: 0,
                child: const ColoredBox(color: Colors.black54),
              ),
              Positioned(
                left: rightPx,
                right: _handleWidth / 2,
                top: 0,
                bottom: 0,
                child: const ColoredBox(color: Colors.black54),
              ),
              // Selection frame
              Positioned(
                left: leftPx,
                width: math.max(0, rightPx - leftPx),
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              // Drag handles
              Positioned.fill(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: _stripHeight,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    overlayShape: SliderComponentShape.noOverlay,
                    rangeThumbShape: _TrimHandleShape(
                      color: primary,
                      width: _handleWidth,
                      height: _stripHeight,
                    ),
                    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                  ),
                  child: RangeSlider(
                    min: 0,
                    max: total,
                    values: RangeValues(
                      _range.start.clamp(0.0, total),
                      _range.end.clamp(0.0, total),
                    ),
                    onChanged: canTrim ? _onRangeChanged : null,
                    onChangeEnd: (_) => HapticFeedback.selectionClick(),
                  ),
                ),
              ),
              // Playhead
              if (_controller != null)
                Positioned(
                  left:
                      _handleWidth / 2 +
                      trackW *
                          (_controller!.value.position.inMilliseconds / total)
                              .clamp(0.0, 1.0) -
                      1,
                  top: -2,
                  bottom: -2,
                  child: const IgnorePointer(
                    child: SizedBox(
                      width: 2,
                      child: ColoredBox(color: AppColors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Rounded rectangle drag handle for the trim bar.
class _TrimHandleShape extends RangeSliderThumbShape {
  const _TrimHandleShape({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(5),
    );
    final canvas = context.canvas;
    canvas.drawRRect(rrect, Paint()..color = color);

    // Grip lines
    final grip =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      grip,
    );
  }
}
