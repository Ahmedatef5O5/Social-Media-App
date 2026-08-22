import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/chat_helper.dart';

class AiTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;
  final int charsPerTick;
  final Duration tickInterval;
  final VoidCallback? onDone;
  final TextDirection? textDirection;
  final TextAlign? textAlign;

  const AiTypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.animate = false,
    this.charsPerTick = 3,
    this.tickInterval = const Duration(milliseconds: 18),
    this.onDone,
    this.textDirection,
    this.textAlign,
  });

  @override
  State<AiTypewriterText> createState() => _AiTypewriterTextState();
}

class _AiTypewriterTextState extends State<AiTypewriterText> {
  late int _revealedLength;
  late List<_CodeFence> _codeFences;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _codeFences = _findCodeFences(widget.text);

    _revealedLength = widget.animate ? 0 : widget.text.length;

    if (widget.animate && widget.text.isNotEmpty) {
      _timer = Timer.periodic(widget.tickInterval, _onTick);
    }
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    final requestedLength = _revealedLength + widget.charsPerTick;

    final nextLength = _getNextRevealLength(requestedLength);

    if (nextLength >= widget.text.length) {
      timer.cancel();

      setState(() {
        _revealedLength = widget.text.length;
      });

      widget.onDone?.call();
      return;
    }

    if (nextLength == _revealedLength) {
      return;
    }

    setState(() {
      _revealedLength = nextLength;
    });
  }

  int _getNextRevealLength(int requestedLength) {
    for (final fence in _codeFences) {
      final isApproachingCodeBlock =
          _revealedLength < fence.openStart &&
          requestedLength >= fence.openStart;

      if (isApproachingCodeBlock) {
        return fence.closeEnd;
      }
    }

    return requestedLength.clamp(0, widget.text.length);
  }

  List<_CodeFence> _findCodeFences(String text) {
    final fences = <_CodeFence>[];

    final lines = text.split('\n');

    var offset = 0;

    int? openStart;
    int? openEnd;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final isLastLine = i == lines.length - 1;

      final lineEnd = offset + line.length + (isLastLine ? 0 : 1);

      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        if (openStart == null) {
          // Opening ```
          openStart = offset;
          openEnd = lineEnd;
        } else {
          // Closing ```
          fences.add(
            _CodeFence(
              openStart: openStart,
              openEnd: openEnd!,
              closeStart: offset,
              closeEnd: lineEnd,
            ),
          );

          openStart = null;
          openEnd = null;
        }
      }

      offset = lineEnd;
    }

    return fences;
  }

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null || href.isEmpty) return;

    final uri = Uri.tryParse(href);

    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  MarkdownStyleSheet _styleSheetFor(TextStyle base) {
    return MarkdownStyleSheet(
      p: base,

      strong: base.copyWith(fontWeight: FontWeight.bold),

      em: base.copyWith(fontStyle: FontStyle.italic),

      listBullet: base,

      h1: base.copyWith(
        fontSize: (base.fontSize ?? 15) + 6,
        fontWeight: FontWeight.bold,
      ),

      h2: base.copyWith(
        fontSize: (base.fontSize ?? 15) + 3,
        fontWeight: FontWeight.bold,
      ),

      h3: base.copyWith(
        fontSize: (base.fontSize ?? 15) + 1,
        fontWeight: FontWeight.bold,
      ),

      code: base.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Colors.black.withValues(alpha: 0.25),
      ),

      codeblockDecoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),

      a: base.copyWith(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),

      blockSpacing: 6,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeLength = _revealedLength.clamp(0, widget.text.length);

    final revealedText =
        safeLength == 0 ? '' : widget.text.substring(0, safeLength);

    return Directionality(
      textDirection:
          widget.textDirection ?? ChatHelper.getTextDirection(widget.text),
      child: MarkdownBody(
        data: revealedText,
        selectable: false,
        softLineBreak: true,
        styleSheet: _styleSheetFor(widget.style),
        onTapLink: _onTapLink,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _CodeFence {
  final int openStart;
  final int openEnd;
  final int closeStart;
  final int closeEnd;

  const _CodeFence({
    required this.openStart,
    required this.openEnd,
    required this.closeStart,
    required this.closeEnd,
  });
}
