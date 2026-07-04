import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cache/repository/media_cache_repository.dart';

class CachedCloudinaryImage extends StatefulWidget {
  const CachedCloudinaryImage({
    super.key,
    required this.secureUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.onReady,
  });

  final String secureUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorWidget;
  final VoidCallback? onReady;

  @override
  State<CachedCloudinaryImage> createState() => _CachedCloudinaryImageState();
}

class _CachedCloudinaryImageState extends State<CachedCloudinaryImage> {
  late Future<String?> _localPathFuture;

  @override
  void initState() {
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
    _localPathFuture =
        widget.secureUrl.isEmpty
            ? Future.value(null)
            : context.read<MediaCacheRepository>().resolveLocalPath(
              widget.secureUrl,
            );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.secureUrl.isEmpty) {
      return _buildError(context, StateError('empty secureUrl'));
    }

    return FutureBuilder<String?>(
      future: _localPathFuture,
      builder: (context, snapshot) {
        final localPath = snapshot.data;

        if (localPath != null) {
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

        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder?.call(context) ??
              SizedBox(width: widget.width, height: widget.height);
        }

        return _buildNetworkFallback(context);
      },
    );
  }

  Widget _buildNetworkFallback(BuildContext context) {
    if (widget.onReady != null) {
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
        imageBuilder: (_, imageProvider) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onReady?.call(),
          );
          return Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
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

  Widget _buildError(BuildContext context, Object error) {
    return widget.errorWidget?.call(context, error) ??
        const Icon(Icons.wifi_off_rounded, size: 20);
  }
}
