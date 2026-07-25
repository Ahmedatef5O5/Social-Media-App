import 'dart:io';
import 'package:audio_decoder/audio_decoder.dart';
import 'package:flutter/foundation.dart';

/// Result of an attempted WAV → M4A (AAC) compression pass.
/// If compression fails for any reason, [wasCompressed] is false and
/// [fileToUpload] simply falls back to the original WAV file — sending a
/// slightly larger voice note is always preferable to failing the send
/// entirely over a non-critical size optimization.
class AudioCompressionResult {
  final File fileToUpload;
  final bool wasCompressed;
  final File originalWavFile;

  const AudioCompressionResult({
    required this.fileToUpload,
    required this.wasCompressed,
    required this.originalWavFile,
  });
}


class AudioCompressionService {
  Future<AudioCompressionResult> compress(File wavFile) async {
    final outputPath = _buildM4aPath(wavFile.path);

    try {
      final resultPath = await AudioDecoder.convertToM4a(
        wavFile.path,
        outputPath,
      );
      final compressedFile = File(resultPath);

      if (await compressedFile.exists() && await compressedFile.length() > 0) {
        return AudioCompressionResult(
          fileToUpload: compressedFile,
          wasCompressed: true,
          originalWavFile: wavFile,
        );
      }
      debugPrint(
        '⚠️ AudioCompressionService: output missing/empty, falling back to WAV',
      );
    } catch (e) {
      debugPrint(
        '⚠️ AudioCompressionService: compression failed ($e), falling back to WAV',
      );
    }

    return AudioCompressionResult(
      fileToUpload: wavFile,
      wasCompressed: false,
      originalWavFile: wavFile,
    );
  }

  Future<void> cleanup(AudioCompressionResult result) async {
    await _safeDelete(result.originalWavFile);
    if (result.fileToUpload.path != result.originalWavFile.path) {
      await _safeDelete(result.fileToUpload);
    }
  }

  String _buildM4aPath(String wavPath) {
    final dotIndex = wavPath.lastIndexOf('.');
    final withoutExt =
        dotIndex == -1 ? wavPath : wavPath.substring(0, dotIndex);
    return '$withoutExt.m4a';
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
