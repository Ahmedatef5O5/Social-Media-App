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

class _MessageLinkPreviewState extends State<MessageLinkPreview>
    with AutomaticKeepAliveClientMixin<MessageLinkPreview> {
  String? _url;
  bool _isOnlyUrl = false;
  LinkPreviewData? _data;
  bool _hasResolved = false;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant MessageLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _resolve();
  }

  void _resolve() {
    if (widget.text.trim().isEmpty) {
      _url = null;
      _data = null;
      _hasResolved = true;
      return;
    }

    final elements = linkify_pkg.linkify(
      widget.text,
      options: const linkify_pkg.LinkifyOptions(humanize: false),
    );
    final urlElements = elements.whereType<linkify_pkg.UrlElement>().toList();

    if (urlElements.isEmpty) {
      _url = null;
      _data = null;
      _hasResolved = true;
      return;
    }

    final url = urlElements.first.url;
    _url = url;
    final withoutUrl =
        widget.text.replaceFirst(urlElements.first.text, '').trim();
    _isOnlyUrl = withoutUrl.isEmpty;

    final cached = LinkPreviewService.instance.peek(url);
    if (cached != null) {
      _data = cached;
      _hasResolved = true;
      return;
    }

    _hasResolved = false;
    LinkPreviewService.instance.fetch(url).then((result) {
      if (!mounted || _url != url) return;
      setState(() {
        _data = result;
        _hasResolved = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_url == null) return widget.textWidget;
    if (!_hasResolved || _data == null || !_data!.hasContent) {
      return widget.textWidget;
    }

    if (_isOnlyUrl) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: LinkPreviewCard(data: _data!, onColoredBubble: widget.isMe),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LinkPreviewCard(data: _data!, onColoredBubble: widget.isMe),
        const SizedBox(height: 6),
        widget.textWidget,
      ],
    );
  }
}
