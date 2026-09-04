import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../helpers/code_language_registry.dart';

/// ChatGPT/Gemini-style code block: dark container, syntax highlighting,
/// and a header row with a copy button + language name/icon. Always renders
/// left-to-right regardless of the surrounding message's direction — code
/// should never follow Arabic (RTL) layout.
class AiCodeBlockView extends StatefulWidget {
  final String code;
  final String language;

  const AiCodeBlockView({
    super.key,
    required this.code,
    required this.language,
  });

  @override
  State<AiCodeBlockView> createState() => _AiCodeBlockViewState();
}

class _AiCodeBlockViewState extends State<AiCodeBlockView> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = CodeLanguageRegistry.resolve(widget.language);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF282C34), // atom-one-dark background
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _copy,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: _copied ? Colors.greenAccent : Colors.white70,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(meta.icon, size: 14, color: meta.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    meta.label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                widget.code,
                language: widget.language.isEmpty ? null : widget.language,
                theme: atomOneDarkTheme,
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
