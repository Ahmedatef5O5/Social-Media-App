import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'ai_code_block_view.dart';

class AiCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    md.Element? codeElement;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        codeElement = child;
        break;
      }
    }

    final rawCode = (codeElement ?? element).textContent;
    final classAttr = codeElement?.attributes['class'] ?? '';

    String language = classAttr.replaceFirst('language-', '').trim();
    if (language.isEmpty) {
      language = 'plaintext';
    }

    return AiCodeBlockView(code: rawCode.trimRight(), language: language);
  }
}
