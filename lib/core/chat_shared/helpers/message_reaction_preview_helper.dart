import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../helpers/bidi_text_helper.dart';
import '../../helpers/file_icon_helper.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

class MessageReactionPreviewHelper {
  MessageReactionPreviewHelper._();

  static const Map<String, String> _reactionEmojis = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
    'care': '🥰',
    'clap': '👏',
    'fire': '🔥',
  };

  static const List<String> _mediaPrefixes = [
    '📷',
    '🎥',
    '🎬',
    '🎤',
    '🖼️',
    '🎞️',
    '🏷️',
    '😊',
    '📞',
    '📎',
  ];

  static String resolveEmoji(String? reactionType) {
    if (reactionType == null || reactionType.trim().isEmpty) return '👍';
    final trimmed = reactionType.trim();
    if (_reactionEmojis.containsValue(trimmed)) {
      return trimmed;
    }
    return _reactionEmojis[trimmed.toLowerCase()] ?? trimmed;
  }

  static bool isMediaMessageType(String? type) {
    switch (type) {
      case 'image':
      case 'video':
      case 'voice':
      case 'gif':
      case 'sticker':
      case 'call':
        return true;
      default:
        return false;
    }
  }

  static String extractCleanFileName(String? raw, {bool keepCaption = false}) {
    if (raw == null || raw.trim().isEmpty) return AppL10n.current.file;
    String clean = raw.trim();
    if (clean.startsWith('📄')) {
      clean = clean.substring('📄'.length).trim();
    }
    if (clean.contains(' • ')) {
      final parts = clean.split(' • ');
      final first = parts.first.trim();
      final rest = parts.sublist(1).join(' • ').trim();
      if (!keepCaption || rest.isEmpty || rest == first || rest == 'File') {
        clean = first;
      } else {
        clean = '$first • $rest';
      }
    }
    return clean.isEmpty ? AppL10n.current.file : clean;
  }

  static String getMessageFallback({
    String? type,
    String? text,
    String? fileName,
    String? caption,
  }) {
    final cleanBody = (text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final cleanFileName = (fileName ?? '').trim();
    final cleanCaption = (caption ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

    if (type == 'file' || type == 'document') {
      final rawName =
          cleanFileName.isNotEmpty
              ? cleanFileName
              : (cleanBody.isNotEmpty ? cleanBody : AppL10n.current.file);
      return '📄 ${extractCleanFileName(rawName)}';
    }

    switch (type) {
      case 'image':
        return cleanCaption.isNotEmpty
            ? '📷 $cleanCaption'
            : AppL10n.current.photo2;
      case 'video':
        return cleanCaption.isNotEmpty
            ? '🎥 $cleanCaption'
            : AppL10n.current.video2;
      case 'voice':
        return AppL10n.current.voiceMessage;
      case 'gif':
        return AppL10n.current.gif;
      case 'sticker':
        return AppL10n.current.sticker2;
      case 'call':
        return AppL10n.current.call2;
      default:
        if (cleanBody.isNotEmpty) return cleanBody;
        if (cleanCaption.isNotEmpty) return cleanCaption;
        if (cleanFileName.isNotEmpty) return cleanFileName;
        return AppL10n.current.attachment;
    }
  }

  static String formatReactionPreview({
    required bool isMe,
    required String reactorName,
    required String? reactionType,
    required String? messageType,
    required String? messageText,
    String? fileName,
    String? caption,
  }) {
    final cleanReactor = reactorName.trim();
    final actor =
        isMe
            ? AppL10n.current.you
            : (cleanReactor.isNotEmpty
                ? (cleanReactor.toLowerCase() == 'deleted account'
                    ? AppL10n.current.deletedAccount
                    : cleanReactor)
                : AppL10n.current.someone);
    final emoji = resolveEmoji(reactionType);
    final snippet = getMessageFallback(
      type: messageType,
      text: messageText,
      fileName: fileName,
      caption: caption,
    );

    if (isMediaMessageType(messageType)) {
      return AppL10n.current.reactWithTo(actor, emoji, snippet);
    }
    return AppL10n.current.reactWithTo2(actor, emoji, snippet);
  }

  static Widget buildDirectionalFilePreview({
    required String fileName,
    required TextStyle style,
    Color? defaultIconColor,
    double iconSize = 14,
    bool quoted = false,
    bool keepCaption = false,
  }) {
    final cleanDisplay = extractCleanFileName(
      fileName,
      keepCaption: keepCaption,
    );
    final fileNameOnly = cleanDisplay.split(' • ').first.trim();

    String ext = '';
    if (fileNameOnly.contains('.')) {
      ext = fileNameOnly.substring(fileNameOnly.lastIndexOf('.') + 1).trim();
    }

    final (icon, color) = FileIconHelper.getIconAndColor(
      ext,
      defaultIconColor ?? Colors.grey.shade600,
    );

    final dir = BidiTextHelper.detectDirection(fileNameOnly);

    return Directionality(
      textDirection: dir,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quoted) Text('"', style: style),
          FaIcon(icon, size: iconSize, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              cleanDisplay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: dir,
              style: style,
            ),
          ),
          if (quoted) Text('"', style: style),
        ],
      ),
    );
  }

  static Widget buildReactionPreviewWidget({
    required String rawPreview,
    required TextStyle style,
    Color? defaultIconColor,
    double iconSize = 13,
  }) {
    final localizedPreview = rawPreview.replaceAll(
      RegExp(r'Deleted Account', caseSensitive: false),
      AppL10n.current.deletedAccount,
    );
    final reactIdx = localizedPreview.indexOf(' react with ');
    final toIdx =
        reactIdx != -1 ? rawPreview.indexOf(' to ', reactIdx + 12) : -1;

    if (reactIdx == -1 || toIdx == -1) {
      final dir = BidiTextHelper.detectDirection(rawPreview);
      return Text(
        rawPreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: dir,
        textAlign: TextAlign.left,
        style: style,
      );
    }

    final prefix = rawPreview.substring(0, toIdx + 4);
    String target = rawPreview.substring(toIdx + 4).trim();

    if (target.length >= 2 && target.startsWith('"') && target.endsWith('"')) {
      target = target.substring(1, target.length - 1).trim();
    }

    if (target.startsWith('📄')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prefix, style: style, textDirection: TextDirection.ltr),
          Flexible(
            child: buildDirectionalFilePreview(
              fileName: target,
              style: style,
              defaultIconColor: defaultIconColor,
              iconSize: iconSize,
              quoted: true,
            ),
          ),
        ],
      );
    }

    for (final mediaEmoji in _mediaPrefixes) {
      if (target.startsWith(mediaEmoji)) {
        final afterEmoji = target.substring(mediaEmoji.length).trim();
        final contentDir = BidiTextHelper.detectDirection(afterEmoji);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prefix, style: style, textDirection: TextDirection.ltr),
            Flexible(
              child: Directionality(
                textDirection: contentDir,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mediaEmoji,
                      style: style,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        afterEmoji,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: contentDir,
                        style: style,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    }

    final textDir = BidiTextHelper.detectDirection(target);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(prefix, style: style, textDirection: TextDirection.ltr),
        Flexible(
          child: Directionality(
            textDirection: textDir,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('"', style: style),
                Flexible(
                  child: Text(
                    target,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: textDir,
                    style: style,
                  ),
                ),
                Text('"', style: style),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
