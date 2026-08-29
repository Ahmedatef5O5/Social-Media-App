import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

final StreamController<String> _globalGifPlayController =
    StreamController<String>.broadcast();

class _GifFrameCache {
  static final Map<String, ui.Image> _frames = {};
  static ui.Image? get(String url) => _frames[url];
  static void put(String url, ui.Image image) => _frames[url] = image;
}

class LoopLimitedGif extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int maxLoops;

  const LoopLimitedGif({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.maxLoops = 3,
  });

  @override
  State<LoopLimitedGif> createState() => _LoopLimitedGifState();
}

class _LoopLimitedGifState extends State<LoopLimitedGif> {
  ui.Image? _thumbnailFrame;
  ui.Image? _playingFrame;
  ui.Codec? _activeCodec;

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _disposed = false;

  late String _instanceId;
  StreamSubscription? _playSub;

  @override
  void initState() {
    super.initState();
    _instanceId = UniqueKey().toString();

    _playSub = _globalGifPlayController.stream.listen((playingId) {
      if (playingId != _instanceId && _isPlaying) {
        _stop();
      }
    });

    final cachedFrame = _GifFrameCache.get(widget.url);
    if (cachedFrame != null) {
      _thumbnailFrame = cachedFrame;
      _isLoading = false;
    } else {
      _loadThumbnail();
    }
  }

  Future<Uint8List> _readCachedBytes() async {
    final file = await DefaultCacheManager().getSingleFile(widget.url);
    return file.readAsBytes();
  }

  Future<void> _loadThumbnail() async {
    try {
      final bytes = await _readCachedBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      if (_disposed) return;
      _GifFrameCache.put(widget.url, frameInfo.image);
      setState(() {
        _thumbnailFrame = frameInfo.image;
        _isLoading = false;
      });
    } catch (e) {
      if (_disposed) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _play() async {
    if (_isPlaying || _isLoading || _hasError) return;

    _globalGifPlayController.add(_instanceId);

    setState(() => _isPlaying = true);
    try {
      final bytes = await _readCachedBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      _activeCodec = codec;
      final frameCount = codec.frameCount;

      int totalLoops = 0;
      while (!_disposed && _isPlaying) {
        for (int i = 0; i < frameCount; i++) {
          if (_disposed || !_isPlaying) {
            break;
          }
          final frameInfo = await codec.getNextFrame();
          if (_disposed) break;

          setState(() {
            _playingFrame = frameInfo.image;
          });
          await Future.delayed(frameInfo.duration);
        }

        if (!_isPlaying) break;

        totalLoops++;
        if (totalLoops >= widget.maxLoops) {
          _stop();
          break;
        }
      }
    } catch (e) {
      _stop();
    }
  }

  void _stop() {
    if (_disposed) return;
    setState(() {
      _isPlaying = false;
      _playingFrame = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _playSub?.cancel();
    _activeCodec?.dispose();
    super.dispose();
  }

  Widget _placeholder(Widget child) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(child: child),
    );
  }

  Widget _loadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // A shimmer skeleton in place of the bubble's actual footprint reads
      // as "content is arriving" rather than a hard block on top of it —
      // and thanks to _GifFrameCache, this only ever shows once per URL
      // for the whole app session, not every time this widget remounts.
      return _loadingSkeleton();
    }
    if (_hasError || _thumbnailFrame == null) {
      return _placeholder(
        const Icon(Icons.broken_image_rounded, color: Colors.grey),
      );
    }

    final displayedFrame =
        _isPlaying ? (_playingFrame ?? _thumbnailFrame!) : _thumbnailFrame!;

    return GestureDetector(
      onTap: _isPlaying ? _stop : _play,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RawImage(image: displayedFrame, fit: widget.fit),
            if (!_isPlaying) const Center(child: ElegantGifOverlay()),
          ],
        ),
      ),
    );
  }
}

class ElegantGifOverlay extends StatefulWidget {
  const ElegantGifOverlay({super.key});

  @override
  State<ElegantGifOverlay> createState() => _ElegantGifOverlayState();
}

class _ElegantGifOverlayState extends State<ElegantGifOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(48, 48),
              painter: _GlassCutoutPainter(progress: _controller.value),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    'GIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlassCutoutPainter extends CustomPainter {
  final double progress;

  _GlassCutoutPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      bgPaint,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              2.1 // سُمك المستطيل
          ..strokeCap = StrokeCap.round;

    final radius = (size.width / 2) - 6.5;

    const int dashCount = 6;
    const double dashSweepAngle = (2 * math.pi) / (dashCount * 2.1);
    final double startAngleOffset = progress * 2 * math.pi;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle =
          startAngleOffset + (i * 2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashSweepAngle,
        false,
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassCutoutPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
