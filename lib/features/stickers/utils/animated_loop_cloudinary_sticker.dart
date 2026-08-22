import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/cache/repository/media_cache_repository.dart';
import 'animated_loop_sticker.dart';

class _StickerPathCache {
  static final Map<String, String> _paths = {};
  static String? get(String url) => _paths[url];
  static void put(String url, String path) => _paths[url] = path;
}

class AnimatedLoopCloudinarySticker extends StatefulWidget {
  final String secureUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int maxLoops;

  const AnimatedLoopCloudinarySticker({
    super.key,
    required this.secureUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.maxLoops = 3,
  });

  @override
  State<AnimatedLoopCloudinarySticker> createState() =>
      _AnimatedLoopCloudinaryStickerState();
}

class _AnimatedLoopCloudinaryStickerState
    extends State<AnimatedLoopCloudinarySticker> {
  String? _syncLocalPath;
  late Future<String?> _localPathFuture;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AnimatedLoopCloudinarySticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secureUrl != widget.secureUrl) {
      setState(_resolve);
    }
  }

  void _resolve() {
    final memCached = _StickerPathCache.get(widget.secureUrl);
    if (memCached != null) {
      _syncLocalPath = memCached;
      _localPathFuture = Future.value(memCached);
      return;
    }

    final repo = context.read<MediaCacheRepository>();

    // Fast path: already on disk, no need to await anything.
    final syncPath = repo.resolveLocalPathSync(widget.secureUrl);
    if (syncPath != null) {
      _StickerPathCache.put(widget.secureUrl, syncPath);
      _syncLocalPath = syncPath;
      _localPathFuture = Future.value(syncPath);
      return;
    }

    _syncLocalPath = null;
    _localPathFuture = repo.resolveLocalPath(widget.secureUrl).then((path) {
      if (path != null) _StickerPathCache.put(widget.secureUrl, path);
      return path;
    });
  }

  Widget _placeholder(BuildContext context) {
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

  Widget _error(BuildContext context, Object error) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_syncLocalPath != null) {
      return AnimatedLoopSticker(
        filePath: _syncLocalPath,
        maxLoops: widget.maxLoops,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: _placeholder,
        errorWidget: _error,
      );
    }

    return FutureBuilder<String?>(
      future: _localPathFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder(context);
        }

        final localPath = snapshot.data;
        if (localPath == null) {
          return AnimatedLoopSticker(
            bytesLoader: () async {
              final uri = Uri.parse(widget.secureUrl);
              final client = HttpClientAdapterHelper();
              return client
                  .getBytes(uri)
                  .then((bytes) => Uint8List.fromList(bytes));
            },
            maxLoops: widget.maxLoops,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            placeholder: _placeholder,
            errorWidget: _error,
          );
        }

        return AnimatedLoopSticker(
          filePath: localPath,
          maxLoops: widget.maxLoops,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: _placeholder,
          errorWidget: _error,
        );
      },
    );
  }
}

class HttpClientAdapterHelper {
  Future<List<int>> getBytes(Uri uri) async {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    client.close();
    return bytes;
  }
}
