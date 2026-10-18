import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/themes/app_colors.dart';

/// Six-box numeric code input. A transparent real [TextField] owns the focus
/// and the keyboard; the boxes are only a rendering of its text. Typing,
/// pasting (see [OtpCodeFieldState.paste]) and the soft keyboard's own paste
/// all go through the same path and auto-submit when [length] digits exist.
class OtpCodeField extends StatefulWidget {
  final int length;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const OtpCodeField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void clear() {
    _ctrl.clear();
    setState(() {});
    if (widget.enabled) _focus.requestFocus();
  }

  /// Reads digits from the clipboard (e.g. "123 456") and submits.
  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    _ctrl.text = digits.substring(0, math.min(widget.length, digits.length));
    _onChanged(_ctrl.text);
  }

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _ctrl.text;
    final activeIndex = _focus.hasFocus ? text.length : -1;

    // Codes are digits: always render left-to-right, even in RTL locales.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.enabled) _focus.requestFocus();
        },
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (i) {
                final filled = i < text.length;
                final active = i == activeIndex && widget.enabled;
                final borderColor =
                    widget.hasError
                        ? Colors.redAccent
                        : active
                        ? AppColors.primaryColor
                        : theme.dividerColor.withValues(alpha: 0.6);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 48,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: active || widget.hasError ? 1.8 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? text[i] : '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
            // The real input: invisible but focusable and hit-testable.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
