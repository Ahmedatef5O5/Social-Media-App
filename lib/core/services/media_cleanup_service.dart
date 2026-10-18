import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';

class MediaCleanupService {
  MediaCleanupService._();

  static final MediaCleanupService instance = MediaCleanupService._();

  Future<void> deleteWithMedia({
    required String table,
    required String id,
  }) async {
    final response = await SupabaseProvider.client.functions.invoke(
      'delete-media-asset',
      body: {'table': table, 'id': id},
    );

    if (response.status != 200) {
      throw Exception(
        'delete_media_asset_failed: ${response.data ?? response.status}',
      );
    }
  }

  Future<void> deleteRawAssets({
    required List<String> publicIds,
    required String resourceType,
  }) async {
    if (publicIds.isEmpty) return;
    try {
      final response = await SupabaseProvider.client.functions.invoke(
        'delete-media-asset',
        body: {
          'mode': 'raw',
          'publicIds': publicIds,
          'resourceType': resourceType,
        },
      );
      if (response.status != 200) {
        debugPrint(
          '[MediaCleanupService] deleteRawAssets failed: '
          '${response.data ?? response.status}',
        );
      }
    } catch (e) {
      debugPrint('[MediaCleanupService] deleteRawAssets error: $e');
    }
  }

  // ── Local temp files produced by the in-app media editor ─────────────────

  static const String _editsDirName = 'media_edits';
  final Set<String> _trackedTempPaths = <String>{};

  Future<Directory> _editsDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _editsDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Reserves a unique tracked path inside the edits temp dir.
  Future<String> createTempPath(String extension) async {
    final dir = await _editsDir();
    final path = p.join(
      dir.path,
      'edit_${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    _trackedTempPaths.add(path);
    return path;
  }

  /// Writes [bytes] to a new tracked temp file.
  Future<File> createTempFile(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    final path = await createTempPath(extension);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  bool isTrackedTempFile(File? file) =>
      file != null && _trackedTempPaths.contains(file.path);

  /// Deletes [file] only if the editor created it (never touches user files).
  Future<void> deleteTempFile(File? file) async {
    if (file == null || !_trackedTempPaths.remove(file.path)) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[MediaCleanupService] deleteTempFile error: $e');
    }
  }

  /// Removes editor temp files older than [maxAge]. Safe to call often.
  Future<void> purgeStaleTempFiles({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final dir = await _editsDir();
      final cutoff = DateTime.now().subtract(maxAge);
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          _trackedTempPaths.remove(entity.path);
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('[MediaCleanupService] purgeStaleTempFiles error: $e');
    }
  }
}
