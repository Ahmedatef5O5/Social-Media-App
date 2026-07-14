import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AnimatedLoopSticker extends StatefulWidget {
  final String? filePath;

  final Future<Uint8List> Function()? bytesLoader;

  final double? width;
  final double? height;
  final BoxFit fit;
  final int maxLoops;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorWidget;

  const AnimatedLoopSticker({
    super.key,
    this.filePath,
    this.bytesLoader,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.maxLoops = 3,
    this.placeholder,
    this.errorWidget,
  }) : assert(
         filePath != null || bytesLoader != null,
         'Provide either filePath or bytesLoader',
       );

  @override
  State<AnimatedLoopSticker> createState() => _AnimatedLoopStickerState();
}

class _AnimatedLoopStickerState extends State<AnimatedLoopSticker>
    with SingleTickerProviderStateMixin {
  ui.Codec? _codec;
  // ignore: unused_field
  ui.FrameInfo? _currentFrame;
  ui.Image? _lastDecodedImage;

  int _frameIndex = 0;
  int _completedLoops = 0;
  bool _isPlaying = false;
  bool _isLoading = true;
  Object? _error;

  Timer? _frameTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnimatedLoopSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _disposeCodec();
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Uint8List bytes;
      if (widget.filePath != null) {
        bytes = await File(widget.filePath!).readAsBytes();
      } else {
        bytes = await widget.bytesLoader!();
      }

      final codec = await ui.instantiateImageCodec(bytes);
      if (!mounted) return;

      _codec = codec;
      _frameIndex = 0;
      _completedLoops = 0;

      if (codec.frameCount <= 1) {
        final frame = await codec.getNextFrame();
        if (!mounted) return;
        setState(() {
          _currentFrame = frame;
          _lastDecodedImage = frame.image;
          _isLoading = false;
          _isPlaying = false;
        });
        return;
      }

      setState(() => _isLoading = false);
      _startPlaying();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  void _startPlaying() {
    if (_codec == null || _codec!.frameCount <= 1) return;
    _isPlaying = true;
    _scheduleNextFrame();
  }

  void _scheduleNextFrame() {
    _frameTimer?.cancel();
    if (!_isPlaying || _codec == null) return;

    _codec!.getNextFrame().then((frame) {
      if (!mounted || !_isPlaying) return;

      setState(() {
        _currentFrame = frame;
        _lastDecodedImage = frame.image;
      });

      final justFinishedLoop = _frameIndex == _codec!.frameCount - 1;
      _frameIndex = (_frameIndex + 1) % _codec!.frameCount;

      if (justFinishedLoop) {
        _completedLoops++;
        if (_completedLoops >= widget.maxLoops) {
          // Freeze on the last rendered frame.
          setState(() => _isPlaying = false);
          return;
        }
      }

      _frameTimer = Timer(frame.duration, _scheduleNextFrame);
    });
  }

  void _replay() {
    if (_codec == null) return;
    setState(() {
      _frameIndex = 0;
      _completedLoops = 0;
    });
    _startPlaying();
  }

  void _stop() {
    _frameTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _onTap() {
    if (_codec == null || _codec!.frameCount <= 1) {
      return; // static, nothing to toggle
    }
    if (_isPlaying) {
      _stop();
    } else {
      _replay();
    }
  }

  void _disposeCodec() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _codec?.dispose();
    _codec = null;
    _currentFrame = null;
  }

  @override
  void dispose() {
    _disposeCodec();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget?.call(context, _error!) ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Icon(Icons.image_not_supported),
          );
    }

    if (_isLoading || _lastDecodedImage == null) {
      return widget.placeholder?.call(context) ??
          SizedBox(width: widget.width, height: widget.height);
    }

    return GestureDetector(
      onTap: _onTap,
      child: RawImage(
        image: _lastDecodedImage,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }
}
