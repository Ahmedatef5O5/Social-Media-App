import '../models/cached_media_model.dart';

extension CloudinaryUrlX on String {
  static const String unknownFeatureFolder = 'unknown';

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  };

  static const Set<String> _audioOnlyExtensions = {
    'm4a',
    'aac',
    'mp3',
    'ogg',
    'wav',
    'opus',
  };

  static const Set<String> _videoExtensions = {'mp4', 'mov', 'webm', 'mkv'};

  static const Set<String> _transformationPrefixes = {
    'f_',
    'q_',
    'w_',
    'h_',
    'c_',
    'g_',
    'e_',
    'so_',
    'eo_',
    'du_',
    'b_',
    'r_',
    'l_',
    'x_',
    'y_',
    'ar_',
    'dpr_',
    'fl_',
    'a_',
  };

  bool get isCloudinaryDeliveryUrl => contains('/upload/');

  CachedMediaType get cachedMediaType {
    final resourceType = _resourceTypeSegment;
    final ext = fileExtension;

    if (resourceType == 'image') return CachedMediaType.image;
    if (resourceType == 'raw') return CachedMediaType.raw;
    if (resourceType == 'video') {
      return _audioOnlyExtensions.contains(ext)
          ? CachedMediaType.audio
          : CachedMediaType.video;
    }

    if (_imageExtensions.contains(ext)) return CachedMediaType.image;
    if (_audioOnlyExtensions.contains(ext)) return CachedMediaType.audio;
    if (_videoExtensions.contains(ext)) return CachedMediaType.video;
    return CachedMediaType.raw;
  }

  String get cloudinaryFeatureFolder {
    final tail = _uploadTail;
    if (tail == null) return unknownFeatureFolder;

    final segments = tail.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return unknownFeatureFolder;

    final folderCandidates = segments.sublist(0, segments.length - 1);

    for (final segment in folderCandidates) {
      if (_isTransformationSegment(segment) || _isVersionSegment(segment)) {
        continue;
      }
      return segment;
    }
    return unknownFeatureFolder;
  }

  String? get cloudinaryVideoThumbnailUrl {
    if (cachedMediaType != CachedMediaType.video) return null;

    const marker = '/video/upload/';
    final idx = indexOf(marker);
    if (idx == -1) return null;

    final head = substring(0, idx + marker.length);
    final tailSegments =
        substring(
          idx + marker.length,
        ).split('/').where((s) => s.isNotEmpty).toList();
    if (tailSegments.isEmpty) return null;

    final cleanSegments =
        tailSegments.where((s) => !_isTransformationSegment(s)).toList();
    if (cleanSegments.isEmpty) return null;

    final fileName = cleanSegments.removeLast();
    final dotIndex = fileName.lastIndexOf('.');
    final fileNameWithoutExt =
        dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);

    final rebuiltPath = [...cleanSegments, '$fileNameWithoutExt.jpg'].join('/');

    return '${head}so_0,f_jpg,q_auto/$rebuiltPath';
  }

  String get cloudinaryLowResPreviewUrl {
    if (!contains('/upload/') || contains('w_60')) return this;
    return replaceFirst('/upload/', '/upload/w_60,q_30,f_auto/');
  }

  // ── internal helpers ──────────────────────────────────────────────

  String? get _uploadTail {
    const marker = '/upload/';
    final idx = indexOf(marker);
    if (idx == -1) return null;
    return substring(idx + marker.length);
  }

  String? get _resourceTypeSegment {
    const marker = '/upload/';
    final idx = indexOf(marker);
    if (idx == -1) return null;
    final before = substring(0, idx).split('/');
    return before.isNotEmpty ? before.last : null;
  }

  String get fileExtension {
    final lastSegment = split('/').last.split('?').first;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) return '';
    return lastSegment.substring(dotIndex + 1).toLowerCase();
  }

  bool _isVersionSegment(String segment) => RegExp(r'^v\d+$').hasMatch(segment);

  bool _isTransformationSegment(String segment) {
    if (segment.contains(',')) return true;
    for (final prefix in _transformationPrefixes) {
      if (segment.startsWith(prefix)) return true;
    }
    return false;
  }
}
