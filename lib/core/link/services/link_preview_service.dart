import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/link/model/link_preview_data.dart';
import '../../../features/group_chats/services/group_chat_services.dart';
import '../../constants/app_images.dart';
import '../../deep_link/services/deep_link_service.dart';

class LinkPreviewService {
  LinkPreviewService._();
  static final instance = LinkPreviewService._();

  static const _successTtl = Duration(days: 7);
  static const _failureTtl = Duration(hours: 12);
  static const _cacheKeyPrefix = 'link_preview:';

  final _dio = dio_pkg.Dio(
    dio_pkg.BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 400,
      headers: {
        'User-Agent':
            'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml',
      },
    ),
  );

  final Map<String, LinkPreviewData?> _memoryCache = {};

  final Map<String, Future<LinkPreviewData?>> _inFlight = {};

  static const _authWalledDomains = ['linkedin.com'];

  static const _genericGateTitleMarkers = [
    'sign up',
    'log in',
    'log into',
    'welcome back',
    'join linkedin',
    'authwall',
  ];

  bool _looksLikeGenericGatePage(String domain, String? title) {
    final isAuthWalled = _authWalledDomains.any((d) => domain.contains(d));
    if (!isAuthWalled) return false;

    final normalizedTitle = (title ?? '').trim().toLowerCase();
    if (normalizedTitle.isEmpty) return true;
    if (normalizedTitle == 'linkedin') return true;
    return _genericGateTitleMarkers.any(normalizedTitle.contains);
  }

  LinkPreviewData? peek(String url) {
    if (_memoryCache.containsKey(url)) return _memoryCache[url];

    final cached = LocalSnapshotStore.instance.readObject(
      '$_cacheKeyPrefix$url',
    );
    if (cached == null) return null;

    final cachedAt = DateTime.tryParse(cached['cachedAt'] as String? ?? '');
    final isFailure = cached['isFailure'] == true;
    final ttl = isFailure ? _failureTtl : _successTtl;
    if (cachedAt == null || DateTime.now().difference(cachedAt) >= ttl) {
      return null;
    }

    final data = isFailure ? null : LinkPreviewData.fromCacheJson(cached);
    _memoryCache[url] = data;
    return data;
  }

  bool hasFreshCacheEntry(String url) {
    if (_memoryCache.containsKey(url)) return true;

    final cached = LocalSnapshotStore.instance.readObject(
      '$_cacheKeyPrefix$url',
    );
    if (cached == null) return false;

    final cachedAt = DateTime.tryParse(cached['cachedAt'] as String? ?? '');
    final isFailure = cached['isFailure'] == true;
    final ttl = isFailure ? _failureTtl : _successTtl;
    return cachedAt != null && DateTime.now().difference(cachedAt) < ttl;
  }

  Future<LinkPreviewData?> fetch(String url) async {
    final peeked = peek(url);
    if (peeked != null || _memoryCache.containsKey(url)) return peeked;

    final pending = _inFlight[url];
    if (pending != null) return pending;

    final future = _fetchAndCache(url);
    _inFlight[url] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(url);
    }
  }

  Future<LinkPreviewData?> _fetchAndCache(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host == DeepLinkService.host) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2 && segments[0] == 'join') {
        final hash = segments[1];
        try {
          final preview = await GroupChatServices().getGroupInvitePreview(hash);
          if (preview.isValid) {
            final data = LinkPreviewData(
              url: url,
              title:
                  preview.groupName != null
                      ? 'Join "${preview.groupName}"'
                      : 'Group Invitation',
              description:
                  (preview.groupTitle != null && preview.groupTitle!.isNotEmpty)
                      ? preview.groupTitle
                      : '${preview.memberCount} member${preview.memberCount == 1 ? '' : 's'} • Tap to join group',
              imageUrl: preview.groupAvatarUrl ?? AppImages.defaultGroupImg,
              siteName: 'Social Media App',
              domain: uri.host,
            );
            _memoryCache[url] = data;
            unawaited(_persistSuccess(url, data));
            return data;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to resolve internal group invite preview: $e');
        }
      }
    }

    final direct = await _fetchDirect(url);
    if (direct != null) {
      _memoryCache[url] = direct;
      unawaited(_persistSuccess(url, direct));
      return direct;
    }

    final viaEdge = await _fetchFromEdgeFunction(url);
    if (viaEdge != null) {
      _memoryCache[url] = viaEdge;
      unawaited(_persistSuccess(url, viaEdge));
      return viaEdge;
    }

    _cacheFailure(url);
    return null;
  }

  Future<LinkPreviewData?> _fetchDirect(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: dio_pkg.Options(responseType: dio_pkg.ResponseType.plain),
      );
      final html = response.data ?? '';
      final data = _parseHtml(url, html);

      if (_looksLikeGenericGatePage(data.domain, data.title)) return null;
      return data.hasContent ? data : null;
    } catch (e) {
      debugPrint('[LinkPreviewService] direct fetch failed for $url: $e');
      return null;
    }
  }

  Future<LinkPreviewData?> _fetchFromEdgeFunction(String url) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'link-preview',
        body: {'url': url},
      );
      final payload = response.data;
      if (payload is! Map || payload['data'] is! Map) return null;

      final d = payload['data'] as Map;
      final title = d['title'] as String?;
      final imageUrl = d['image_url'] as String?;
      if ((title == null || title.isEmpty) &&
          (imageUrl == null || imageUrl.isEmpty)) {
        return null;
      }

      final domain =
          (d['domain'] as String?) ?? (Uri.tryParse(url)?.host ?? url);
      if (_looksLikeGenericGatePage(domain, title)) return null;

      return LinkPreviewData(
        url: url,
        title: title,
        description: d['description'] as String?,
        imageUrl: imageUrl,
        siteName: d['site_name'] as String?,
        domain: domain,
      );
    } catch (e) {
      debugPrint('[LinkPreviewService] edge function failed for $url: $e');
      return null;
    }
  }

  Future<void> _persistSuccess(String url, LinkPreviewData data) {
    return LocalSnapshotStore.instance.saveObject('$_cacheKeyPrefix$url', {
      ...data.toCacheJson(),
      'cachedAt': DateTime.now().toIso8601String(),
      'isFailure': false,
    });
  }

  void _cacheFailure(String url) {
    _memoryCache[url] = null;
    unawaited(
      LocalSnapshotStore.instance.saveObject('$_cacheKeyPrefix$url', {
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
        'isFailure': true,
      }),
    );
  }

  LinkPreviewData _parseHtml(String url, String html) {
    final document = html_parser.parse(html);

    final title = _unescape(
      _metaContent(document, 'og:title') ??
          _metaContent(document, 'twitter:title') ??
          document.querySelector('title')?.text,
    );
    final description = _unescape(
      _metaContent(document, 'og:description') ??
          _metaContent(document, 'twitter:description') ??
          _metaContent(document, 'description'),
    );

    String? image =
        _metaContent(document, 'og:image:secure_url') ??
        _metaContent(document, 'og:image') ??
        _metaContent(document, 'twitter:image');

    if (image != null && !image.startsWith('http')) {
      try {
        image = Uri.parse(url).resolve(image).toString();
      } catch (_) {
        image = null;
      }
    }

    final siteName = _unescape(
      _metaContent(document, 'og:site_name') ??
          _metaContent(document, 'twitter:site'),
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

  String? _metaContent(html_dom.Document document, String property) {
    final byProperty = document.querySelector('meta[property="$property"]');
    final byPropertyContent = byProperty?.attributes['content'];
    if (byPropertyContent != null && byPropertyContent.trim().isNotEmpty) {
      return byPropertyContent;
    }

    final byName = document.querySelector('meta[name="$property"]');
    final byNameContent = byName?.attributes['content'];
    if (byNameContent != null && byNameContent.trim().isNotEmpty) {
      return byNameContent;
    }

    return null;
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
