import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../cache/repository/media_cache_repository.dart';

class CachedCloudinaryImage extends StatefulWidget {
  final String secureUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorWidget;
  final VoidCallback? onReady;
  final bool isAvatar;

  const CachedCloudinaryImage({
    super.key,
    required this.secureUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.onReady,
    this.isAvatar = false,
  });

  @override
  State<CachedCloudinaryImage> createState() => _CachedCloudinaryImageState();
}

class _CachedCloudinaryImageState extends State<CachedCloudinaryImage> {
  late Future<String?> _localPathFuture;
  String? _syncLocalPath;

  String get _optimizedUrl {
    if (widget.secureUrl.isEmpty ||
        !widget.secureUrl.contains('cloudinary.com')) {
      return widget.secureUrl;
    }

    String finalUrl = widget.secureUrl;

    if (!finalUrl.contains('q_auto')) {
      finalUrl = finalUrl.replaceFirst('/upload/', '/upload/q_auto,f_auto/');
    }

    finalUrl = finalUrl
        .replaceAll(RegExp(r'\.heic$', caseSensitive: false), '.jpg')
        .replaceAll(RegExp(r'\.heif$', caseSensitive: false), '.jpg');

    return finalUrl;
  }

  @override
  void initState() {
    if (!widget.secureUrl.startsWith('assets/')) {
      _localPathFuture = context.read<MediaCacheRepository>().resolveLocalPath(
        _optimizedUrl,
      );
    }
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant CachedCloudinaryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secureUrl != widget.secureUrl) {
      setState(_resolve);
    }
  }

  void _resolve() {
    if (widget.secureUrl.isEmpty) {
      _syncLocalPath = null;
      _localPathFuture = Future.value(null);
      return;
    }

    final repo = context.read<MediaCacheRepository>();

    final syncPath = repo.resolveLocalPathSync(widget.secureUrl);

    if (syncPath != null) {
      _syncLocalPath = syncPath;
      _localPathFuture = Future.value(syncPath);
      return;
    }
    _syncLocalPath = null;
    _localPathFuture = repo.resolveLocalPath(widget.secureUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.secureUrl.isEmpty || widget.secureUrl == 'asset:default') {
      return _buildDefaultPlaceholder();
    }

    if (widget.secureUrl.startsWith('assets/')) {
      return Image.asset(
        widget.secureUrl,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder:
            (context, error, stackTrace) => _buildError(context, error),
      );
    }
    if (widget.secureUrl.isEmpty) {
      return _buildError(context, StateError('empty secureUrl'));
    }
    if (_syncLocalPath != null) {
      return _buildImageFile(_syncLocalPath!);
    }

    return FutureBuilder<String?>(
      future: _localPathFuture,
      builder: (context, snapshot) {
        final localPath = snapshot.data;

        if (localPath != null) {
          return _buildImageFile(localPath);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder != null
              ? widget.placeholder!(context)
              : _buildDefaultPlaceholder();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildNetworkFallback(context);
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder?.call(context) ??
              SizedBox(width: widget.width, height: widget.height);
        }
        return Image.file(
          File(snapshot.data!),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _buildNetworkFallback(context),
        );
      },
    );
  }

  Widget _buildImageFile(String localPath) {
    return Image.file(
      File(localPath),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      frameBuilder:
          widget.onReady == null
              ? null
              : (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => widget.onReady?.call(),
                  );
                }
                return child;
              },
      errorBuilder: (_, error, __) => _buildNetworkFallback(context),
    );
  }

  Widget _buildNetworkFallback(BuildContext context) {
    if (widget.onReady != null) {
      return CachedNetworkImage(
        imageUrl: _optimizedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder:
            widget.placeholder != null
                ? (_, __) => widget.placeholder!(context)
                : (_, __) => _buildDefaultPlaceholder(),
        errorWidget: (_, __, error) => _buildError(context, error),
        imageBuilder:
            widget.onReady != null
                ? (_, imageProvider) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => widget.onReady?.call(),
                  );
                  return Image(
                    image: imageProvider,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                  );
                }
                : null,
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.secureUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder:
          widget.placeholder != null
              ? (_, __) => widget.placeholder!(context)
              : null,
      errorWidget: (_, __, error) => _buildError(context, error),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: widget.isAvatar ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(context, error);
    }

    double iconSize = 20.0;
    if (widget.width != null && widget.width!.isFinite) {
      iconSize = widget.width! * 0.5;
    } else if (widget.height != null && widget.height!.isFinite) {
      iconSize = widget.height! * 0.5;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: widget.isAvatar ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        widget.isAvatar ? Icons.person : Icons.image_not_supported,
        color: Colors.grey[400],
        size: iconSize,
      ),
    );
  }
}
