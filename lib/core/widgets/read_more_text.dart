import 'package:flutter/material.dart';
import '../helpers/chat_helper.dart';

typedef ReadMoreContentBuilder =
    Widget Function(BuildContext context, int? maxLines, TextOverflow overflow);

class ReadMoreText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int collapsedMaxLines;
  final TextDirection? textDirection;
  final CrossAxisAlignment? crossAxisAlignment;
  final TextStyle? toggleTextStyle;
  final EdgeInsetsGeometry togglePadding;
  final ReadMoreContentBuilder contentBuilder;
  final double? textMaxWidth;

  const ReadMoreText({
    super.key,
    required this.text,
    required this.style,
    required this.contentBuilder,
    this.collapsedMaxLines = 6,
    this.textDirection,
    this.crossAxisAlignment,
    this.toggleTextStyle,
    this.togglePadding = const EdgeInsets.only(top: 4),
    this.textMaxWidth,
  });

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final direction =
        widget.textDirection ?? ChatHelper.getTextDirection(trimmed);
    final isArabic = direction == TextDirection.rtl;

    final readMoreLabel = isArabic ? '...قراءة المزيد' : 'Read more...';
    final readLessLabel = isArabic ? 'عرض أقل' : 'Show less';

    final crossAxis =
        widget.crossAxisAlignment ??
        (isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start);

    Widget buildContent(double maxWidth) {
      final textPainter = TextPainter(
        text: TextSpan(text: trimmed, style: widget.style),
        maxLines: widget.collapsedMaxLines,
        textDirection: direction,
      )..layout(maxWidth: maxWidth);

      final isOverflowing = textPainter.didExceedMaxLines;
      final effectiveMaxLines = _isExpanded ? null : widget.collapsedMaxLines;
      final effectiveOverflow =
          _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis;

      return Column(
        crossAxisAlignment: crossAxis,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.contentBuilder(context, effectiveMaxLines, effectiveOverflow),
          if (isOverflowing)
            Padding(
              padding: widget.togglePadding,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded ? readLessLabel : readMoreLabel,
                  style:
                      widget.toggleTextStyle ??
                      widget.style.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            ),
        ],
      );
    }

    if (widget.textMaxWidth != null) {
      return buildContent(widget.textMaxWidth!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return buildContent(constraints.maxWidth);
      },
    );
  }
}
