import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/link/model/link_preview_data.dart';
import '../../../core/link/services/link_preview_service.dart';
import '../../../core/toast/app_toast.dart';
import '../models/social_platform_info.dart';

class SocialMediaPreviewCard extends StatefulWidget {
  final SocialPlatformInfo platform;
  final String rawValue;

  const SocialMediaPreviewCard({
    super.key,
    required this.platform,
    required this.rawValue,
  });

  @override
  State<SocialMediaPreviewCard> createState() => _SocialMediaPreviewCardState();
}

class _SocialMediaPreviewCardState extends State<SocialMediaPreviewCard> {
  late final String _url;
  late final Future<LinkPreviewData?> _previewFuture;

  static const _imageHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  };

  @override
  void initState() {
    super.initState();
    _url = widget.platform.normalizeToUrl(widget.rawValue);
    _previewFuture = LinkPreviewService.instance.fetch(_url);
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(_url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppToast.error('Could not open ${widget.platform.label} link');
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (mounted) AppToast.success('Link copied');
  }

  Future<void> _shareLink() async {
    await SharePlus.instance.share(
      ShareParams(text: _url, subject: 'Check out this link!'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLinkedIn = widget.platform.label.toLowerCase().contains(
      'linkedin',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<LinkPreviewData?>(
        future: _previewFuture,
        builder: (context, snapshot) {
          final preview = snapshot.data;
          final hasRichImage = preview?.hasImage ?? false;

          Widget cardContent;

          if (hasRichImage) {
            cardContent = _RichPreview(
              key: const ValueKey('rich'),
              platform: widget.platform,
              preview: preview!,
              imageHeaders: _imageHeaders,
            );
          } else if (isLinkedIn) {
            cardContent = _StaticBrandRichCard(
              key: const ValueKey('linkedin_static'),
              platform: widget.platform,
              title: 'LinkedIn Profile',
              description: 'View professional profile on LinkedIn',
            );
          } else {
            cardContent = _CompactBrandCard(
              key: const ValueKey('compact'),
              platform: widget.platform,
              rawValue: widget.rawValue,
              fallbackTitle: preview?.title,
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  InkWell(
                    onTap: _open,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      child: cardContent,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _ActionButton(
                      icon: Icons.share_rounded,
                      onTap: _shareLink,
                    ),
                  ),

                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      onTap: _copyLink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RichPreview extends StatelessWidget {
  final SocialPlatformInfo platform;
  final LinkPreviewData preview;
  final Map<String, String> imageHeaders;

  const _RichPreview({
    super.key,
    required this.platform,
    required this.preview,
    required this.imageHeaders,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: preview.imageUrl!,
            fit: BoxFit.cover,
            httpHeaders: imageHeaders,
            errorWidget:
                (_, __, ___) => _CompactBrandCard(
                  platform: platform,
                  rawValue: preview.title ?? '',
                ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.35, 1],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: platform.brandColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(platform.icon, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 44,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (preview.title?.trim().isNotEmpty ?? false)
                      ? preview.title!.trim()
                      : platform.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                if ((preview.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    preview.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        preview.domain.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticBrandRichCard extends StatelessWidget {
  final SocialPlatformInfo platform;
  final String title;
  final String description;

  const _StaticBrandRichCard({
    super.key,
    required this.platform,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(platform.brandColor, Colors.white, 0.15) ??
                      platform.brandColor,
                  platform.brandColor,
                  Color.lerp(platform.brandColor, Colors.black, 0.3) ??
                      platform.brandColor,
                ],
              ),
            ),
          ),

          Positioned(
            right: -24,
            bottom: -24,
            child: Transform.rotate(
              angle: -0.15,
              child: FaIcon(
                platform.icon,
                size: 140,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.35, 1],
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: platform.brandColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(platform.icon, color: Colors.white, size: 14),
              ),
            ),
          ),

          Positioned(
            left: 12,
            right: 44,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        platform.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBrandCard extends StatelessWidget {
  final SocialPlatformInfo platform;
  final String rawValue;
  final String? fallbackTitle;

  const _CompactBrandCard({
    super.key,
    required this.platform,
    required this.rawValue,
    this.fallbackTitle,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle =
        (fallbackTitle != null && fallbackTitle!.trim().isNotEmpty)
            ? fallbackTitle!.trim()
            : rawValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            platform.brandColor,
            Color.lerp(platform.brandColor, Colors.black, 0.3)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: platform.brandColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(platform.icon, color: Colors.white, size: 19),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  platform.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _ActionButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
