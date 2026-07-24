import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart' as linkify_pkg;
import '../model/link_preview_data.dart';
import '../services/link_preview_service.dart';
import 'link_preview_card.dart';

class MessageLinkPreview extends StatefulWidget {
  final String text;
  final bool isMe;
  final Widget textWidget;

  const MessageLinkPreview({
    super.key,
    required this.text,
    this.isMe = false,
    required this.textWidget,
  });

  static String? extractFirstUrl(String text) {
    if (text.trim().isEmpty) return null;
    for (final el in linkify_pkg.linkify(
      text,
      options: const linkify_pkg.LinkifyOptions(humanize: false),
    )) {
      if (el is linkify_pkg.UrlElement) return el.url;
    }
    return null;
  }

  @override
  State<MessageLinkPreview> createState() => _MessageLinkPreviewState();
}

class _MessageLinkPreviewState extends State<MessageLinkPreview> {
  String? _url;
  bool _isOnlyUrl = false;
  Future<LinkPreviewData?>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MessageLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _load();
  }

  void _load() {
    if (widget.text.trim().isEmpty) {
      _url = null;
      _future = null;
      return;
    }

    final elements = linkify_pkg.linkify(
      widget.text,
      options: const linkify_pkg.LinkifyOptions(humanize: false),
    );

    final urlElements = elements.whereType<linkify_pkg.UrlElement>().toList();

    if (urlElements.isNotEmpty) {
      _url = urlElements.first.url;

      final originalTextWithoutUrl =
          widget.text.replaceFirst(urlElements.first.text, '').trim();
      _isOnlyUrl = originalTextWithoutUrl.isEmpty;

      _future = LinkPreviewService.instance.fetch(_url!);
    } else {
      _url = null;
      _future = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) return widget.textWidget;

    return FutureBuilder<LinkPreviewData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.textWidget;
        }

        final data = snapshot.data;
        if (data == null || !data.hasContent) return widget.textWidget;

        if (_isOnlyUrl) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: LinkPreviewCard(data: data, isMe: widget.isMe),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LinkPreviewCard(data: data, isMe: widget.isMe),
              const SizedBox(height: 6),
              widget.textWidget,
            ],
          );
        }
      },
    );
  }
}
