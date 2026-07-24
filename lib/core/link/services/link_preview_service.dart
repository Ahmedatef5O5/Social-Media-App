import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/link/model/link_preview_data.dart';

class LinkPreviewService {
  LinkPreviewService._();
  static final instance = LinkPreviewService._();

  static const _cacheTtl = Duration(days: 7);
  static const _cacheKeyPrefix = 'link_preview:';

  final _dio = dio_pkg.Dio(
    dio_pkg.BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      followRedirects: true,
      headers: {
        'User-Agent':
            'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    ),
  );

  final Map<String, LinkPreviewData?> _memoryCache = {};

  Future<LinkPreviewData?> fetch(String url) async {
    if (_memoryCache.containsKey(url)) return _memoryCache[url];

    final cacheKey = '$_cacheKeyPrefix$url';
    final cached = LocalSnapshotStore.instance.readObject(cacheKey);
    if (cached != null) {
      final cachedAt = DateTime.tryParse(cached['cachedAt'] as String? ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
        final data = LinkPreviewData.fromCacheJson(cached);
        _memoryCache[url] = data;
        return data;
      }
    }

    try {
      final response = await _dio.get<String>(
        url,
        options: dio_pkg.Options(responseType: dio_pkg.ResponseType.plain),
      );
      final html = response.data ?? '';
      final data = _parseHtml(url, html);
      _memoryCache[url] = data;
      unawaited(
        LocalSnapshotStore.instance.saveObject(cacheKey, {
          ...data.toCacheJson(),
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );
      return data;
    } catch (e) {
      debugPrint('[LinkPreviewService] failed for $url: $e');
      _memoryCache[url] = null;
      return null;
    }
  }

  LinkPreviewData _parseHtml(String url, String html) {
    final title = _unescape(
      _meta(html, 'og:title') ??
          _meta(html, 'twitter:title') ??
          _titleTag(html),
    );
    final description = _unescape(
      _meta(html, 'og:description') ??
          _meta(html, 'twitter:description') ??
          _meta(html, 'description'),
    );

    String? image = _meta(html, 'og:image') ?? _meta(html, 'twitter:image');

    if (image != null && !image.startsWith('http')) {
      try {
        image = Uri.parse(url).resolve(image).toString();
      } catch (_) {}
    }

    final siteName = _unescape(
      _meta(html, 'og:site_name') ?? _meta(html, 'twitter:site'),
    );

    final uri = Uri.tryParse(url);
    final domain = uri?.host.replaceFirst('www.', '') ?? url;

    return LinkPreviewData(
      url: url,
      title: title?.trim(),
      description: description?.trim(),
      imageUrl: image,
      siteName: siteName,
      domain: domain,
    );
  }

  String? _meta(String html, String property) {
    final patterns = [
      RegExp(
        '<meta[^>]+(?:property|name)=["\']$property["\'][^>]+content=["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']*)["\'][^>]+(?:property|name)=["\']$property["\']',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final match = p.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _titleTag(String html) {
    final match = RegExp(
      r'<title[^>]*>([^<]*)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1);
  }

  String? _unescape(String? input) {
    if (input == null) return null;

    var decoded = input
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    decoded = decoded.replaceAllMapped(RegExp(r'&#(x)?([0-9a-fA-F]+);'), (
      match,
    ) {
      final isHex = match.group(1) == 'x';
      final value = match.group(2)!;
      final intValue = int.tryParse(value, radix: isHex ? 16 : 10);
      if (intValue != null) {
        return String.fromCharCode(intValue);
      }
      return match.group(0)!;
    });

    return decoded;
  }
}
