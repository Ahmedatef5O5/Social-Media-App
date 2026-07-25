import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Encapsulates chunk-based voice recording plus seamless WAV (PCM)
/// concatenation of the recorded chunks.

class VoiceChunkRecorderService {
  VoiceChunkRecorderService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  final List<String> _chunkPaths = [];
  String? _activeChunkPath;
  File? _lastMergedFile;

  static const _recordConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 22050,
    numChannels: 1,
  );

  Future<bool> get hasPermission => _recorder.hasPermission();

  Future<Amplitude> getAmplitude() => _recorder.getAmplitude();

  Future<String> _newChunkPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final index = _chunkPaths.length;
    return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}_p$index.wav';
  }

  Future<void> start() async {
    await _discardEverything();
    final path = await _newChunkPath();
    await _recorder.start(_recordConfig, path: path);
    _activeChunkPath = path;
  }

  Future<void> pause() async {
    if (_activeChunkPath == null) return;
    final expectedPath = _activeChunkPath!;
    String? stoppedPath;
    try {
      stoppedPath = await _recorder.stop();
    } catch (_) {}
    _activeChunkPath = null;

    final finalizedPath = stoppedPath ?? expectedPath;
    if (await _waitForFileReady(finalizedPath)) {
      _chunkPaths.add(finalizedPath);
    }
  }

  /// Starts a brand new chunk, continuing the same logical recording.
  Future<void> resume() async {
    if (_activeChunkPath != null) return;
    final path = await _newChunkPath();
    await _recorder.start(_recordConfig, path: path);
    _activeChunkPath = path;
  }

  Future<File?> previewMergedSoFar() async {
    if (_chunkPaths.isEmpty) return null;
    if (_chunkPaths.length == 1) return File(_chunkPaths.first);
    return _mergeChunks(_chunkPaths, prefix: 'voice_preview');
  }

  Future<File?> finishAndBuild() async {
    if (_activeChunkPath != null) {
      final expectedPath = _activeChunkPath!;
      String? stoppedPath;
      try {
        stoppedPath = await _recorder.stop();
      } catch (_) {}
      _activeChunkPath = null;

      final finalizedPath = stoppedPath ?? expectedPath;
      if (await _waitForFileReady(finalizedPath)) {
        _chunkPaths.add(finalizedPath);
      }
    }

    if (_chunkPaths.isEmpty) return null;

    if (_chunkPaths.length == 1) {
      final single = File(_chunkPaths.first);
      _chunkPaths.clear();
      return single;
    }

    final merged = await _mergeChunks(_chunkPaths, prefix: 'voice_final');
    await _deletePaths(_chunkPaths);
    _chunkPaths.clear();
    return merged;
  }

  /// Cancels the recording entirely, deleting every chunk produced so far.
  Future<void> cancelAndCleanup() => _discardEverything();

  Future<void> _discardEverything() async {
    if (_activeChunkPath != null) {
      try {
        await _recorder.stop();
      } catch (_) {}
      await _deletePaths([_activeChunkPath!]);
      _activeChunkPath = null;
    }
    await _deletePaths(_chunkPaths);
    _chunkPaths.clear();
    if (_lastMergedFile != null) {
      await _deletePaths([_lastMergedFile!.path]);
      _lastMergedFile = null;
    }
  }

  Future<bool> _waitForFileReady(String path, {int retries = 10}) async {
    final file = File(path);
    while (retries-- > 0) {
      if (await file.exists() && await file.length() > 44) return true;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return await file.exists();
  }

  // ---------------------------------------------------------------------
  // WAV merge internals
  // ---------------------------------------------------------------------

  Future<File> _mergeChunks(
    List<String> paths, {
    required String prefix,
  }) async {
    Uint8List? templateFmtChunk;
    final dataSegments = <Uint8List>[];

    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      final info = _parseWavHeader(bytes);
      if (info == null) continue; // skip an unreadable chunk rather than
      // losing the whole recording.

      templateFmtChunk ??= info.fmtChunkBytes;
      dataSegments.add(
        bytes.sublist(info.dataOffset, info.dataOffset + info.dataSize),
      );
    }

    if (templateFmtChunk == null || dataSegments.isEmpty) {
      throw const FormatException('No valid WAV chunks available to merge.');
    }

    final totalDataSize = dataSegments.fold<int>(
      0,
      (sum, seg) => sum + seg.length,
    );

    final dir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final output = File(outputPath);

    final sink = output.openWrite();
    try {
      sink.add(
        _buildWavHeader(fmtChunk: templateFmtChunk, dataSize: totalDataSize),
      );
      for (final segment in dataSegments) {
        sink.add(segment);
      }
    } finally {
      await sink.close();
    }

    _lastMergedFile = output;
    return output;
  }

  _WavHeaderInfo? _parseWavHeader(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (ascii.decode(bytes.sublist(0, 4)) != 'RIFF') return null;
    if (ascii.decode(bytes.sublist(8, 12)) != 'WAVE') return null;

    int offset = 12;
    Uint8List? fmtChunk;
    int dataOffset = -1;
    int dataSize = 0;

    while (offset + 8 <= bytes.length) {
      final chunkId = ascii.decode(bytes.sublist(offset, offset + 4));
      final chunkSize = _readUint32LE(bytes, offset + 4);
      final chunkDataStart = offset + 8;

      if (chunkId == 'fmt ') {
        fmtChunk = bytes.sublist(offset, chunkDataStart + chunkSize);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataStart;
        dataSize = chunkSize;
        break;
      }

      // Chunks are word-aligned (padded to an even number of bytes).
      offset = chunkDataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }

    if (fmtChunk == null || dataOffset == -1) return null;

    final actualRemaining = bytes.length - dataOffset;
    final effectiveDataSize =
        (dataSize <= 0 || dataSize > actualRemaining)
            ? actualRemaining
            : dataSize;

    return _WavHeaderInfo(
      fmtChunkBytes: fmtChunk,
      dataOffset: dataOffset,
      dataSize: effectiveDataSize,
    );
  }

  Uint8List _buildWavHeader({
    required Uint8List fmtChunk,
    required int dataSize,
  }) {
    final builder = BytesBuilder();
    builder.add(ascii.encode('RIFF'));
    final riffChunkSize = 4 + fmtChunk.length + 8 + dataSize;
    builder.add(_uint32LE(riffChunkSize));
    builder.add(ascii.encode('WAVE'));
    builder.add(fmtChunk);
    builder.add(ascii.encode('data'));
    builder.add(_uint32LE(dataSize));
    return builder.toBytes();
  }

  int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  Uint8List _uint32LE(int value) {
    final b = Uint8List(4);
    b[0] = value & 0xFF;
    b[1] = (value >> 8) & 0xFF;
    b[2] = (value >> 16) & 0xFF;
    b[3] = (value >> 24) & 0xFF;
    return b;
  }

  Future<void> _deletePaths(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await _discardEverything();
    await _recorder.dispose();
  }
}

class _WavHeaderInfo {
  final Uint8List fmtChunkBytes;
  final int dataOffset;
  final int dataSize;

  const _WavHeaderInfo({
    required this.fmtChunkBytes,
    required this.dataOffset,
    required this.dataSize,
  });
}
