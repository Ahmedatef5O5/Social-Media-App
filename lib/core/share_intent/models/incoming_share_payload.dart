import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum IncomingShareKind { text, image, video, document, unsupported }

class IncomingSharePayload {
  final IncomingShareKind kind;
  final String? text;
  final List<SharedMediaFile> files;

  const IncomingSharePayload._({
    required this.kind,
    this.text,
    this.files = const [],
  });

  bool get isText => kind == IncomingShareKind.text;
  bool get isSingleFile => files.length == 1;
  bool get isMultipleFiles => files.length > 1;

  static IncomingSharePayload? fromSharedFiles(List<SharedMediaFile> raw) {
    if (raw.isEmpty) return null;

    final first = raw.first;

    // Text / URL share — the library puts the actual string content in `path`.
    if (first.type == SharedMediaType.text ||
        first.type == SharedMediaType.url) {
      final content = first.path.trim();
      if (content.isEmpty) return null;
      return IncomingSharePayload._(
        kind: IncomingShareKind.text,
        text: content,
      );
    }

    if (first.type == SharedMediaType.image) {
      return IncomingSharePayload._(kind: IncomingShareKind.image, files: raw);
    }

    if (first.type == SharedMediaType.video) {
      return IncomingSharePayload._(kind: IncomingShareKind.video, files: raw);
    }

    // Anything else (SharedMediaType.file) → treated as a generic document.
    return IncomingSharePayload._(kind: IncomingShareKind.document, files: raw);
  }
}
