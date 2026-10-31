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
            ? '$cleanCaption 📷'
            : AppL10n.current.photo2;
      case 'video':
        return cleanCaption.isNotEmpty
            ? '$cleanCaption 🎥'
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

    final enReactIdx = localizedPreview.indexOf(' react with ');
    final enToIdx =
        enReactIdx != -1
            ? localizedPreview.indexOf(' to ', enReactIdx + 12)
            : -1;

    final arReactIdx = localizedPreview.indexOf(' تفاعل بـ ');
    final arToIdx =
        arReactIdx != -1
            ? localizedPreview.indexOf(' على ', arReactIdx + 10)
            : -1;

    final isEn = enReactIdx != -1 && enToIdx != -1;
    final isAr = arReactIdx != -1 && arToIdx != -1;

    if (!isEn && !isAr) {
      final isRtlLocale = AppL10n.current.localeName.toLowerCase().startsWith('ar');
      return Text(
        rawPreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection:
            isRtlLocale
                ? TextDirection.rtl
                : BidiTextHelper.detectDirection(rawPreview),
        textAlign: isRtlLocale ? TextAlign.right : TextAlign.left,
        style: style,
      );
    }

    if (isAr) {
      final actor = rawPreview.substring(0, arReactIdx).trim();
      final emoji = rawPreview.substring(arReactIdx + 10, arToIdx).trim();
      String target = rawPreview.substring(arToIdx + 5).trim();

      if (target.startsWith('“') && target.endsWith('”')) {
        target = target.substring(1, target.length - 1).trim();
      } else if (target.length >= 2 &&
          target.startsWith('"') &&
          target.endsWith('"')) {
        target = target.substring(1, target.length - 1).trim();
      }

      if (target.startsWith('📄')) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$actor تفاعل بـ $emoji على ',
              style: style,
              textDirection: TextDirection.rtl,
            ),
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

      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$actor ',
              style: style.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: 'تفاعل بـ $emoji على '),
            TextSpan(text: '“$target”', style: style),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      );
    }

    // الحالة الإنجليزية
    final actor = rawPreview.substring(0, enReactIdx).trim();
    final emoji = rawPreview.substring(enReactIdx + 12, enToIdx).trim();
    String target = rawPreview.substring(enToIdx + 4).trim();

    if (target.length >= 2 &&
        target.startsWith('"') &&
        target.endsWith('"')) {
      target = target.substring(1, target.length - 1).trim();
    }

    if (target.startsWith('📄')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$actor reacted with $emoji to ',
            style: style,
            textDirection: TextDirection.ltr,
          ),
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

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$actor ',
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: 'reacted with $emoji to '),
          TextSpan(text: '"$target"', style: style),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
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
}