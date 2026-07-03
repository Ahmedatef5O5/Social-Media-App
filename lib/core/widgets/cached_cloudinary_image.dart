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
  });

  final String secureUrl;
  final BoxFit fit;

  @override
  State<CachedCloudinaryImage> createState() => _CachedCloudinaryImageState();
}

class _CachedCloudinaryImageState extends State<CachedCloudinaryImage> {
  late final Future<String?> _localPathFuture = context
      .read<MediaCacheRepository>()
      .resolveLocalPath(widget.secureUrl);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _localPathFuture,
      builder: (context, snapshot) {
        final localPath = snapshot.data;
        if (localPath != null) {
          return Image.file(File(localPath), fit: widget.fit);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(color: Color(0x11000000));
        }
        return CachedNetworkImage(
          imageUrl: widget.secureUrl,
          fit: widget.fit,
          errorWidget:
              (_, __, ___) => const Icon(Icons.wifi_off_rounded, size: 20),
        );
      },
    );
  }
}
