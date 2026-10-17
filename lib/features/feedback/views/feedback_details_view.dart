import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/comments/widgets/comment_voice_player.dart';
import 'package:social_media_app/features/settings/widgets/settings_detail_sliver_app_bar.dart';
import 'package:social_media_app/features/settings/widgets/settings_surface_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback_models.dart';
import '../services/feedback_service.dart';
import '../widgets/feedback_skeletons.dart';
import '../widgets/feedback_star_rating_bar.dart';
import '../widgets/feedback_status_chip.dart';

/// Self-contained so it can be opened from a push notification (cold start
/// included) with nothing but a `feedbackId`. Updates live while open.
class FeedbackDetailsView extends StatefulWidget {
  final String feedbackId;
  final FeedbackService? service;

  const FeedbackDetailsView({
    super.key,
    required this.feedbackId,
    this.service,
  });

  @override
  State<FeedbackDetailsView> createState() => _FeedbackDetailsViewState();
}

class _FeedbackDetailsViewState extends State<FeedbackDetailsView> {
  late final FeedbackService _service = widget.service ?? FeedbackService();
  RealtimeChannel? _channel;
  Timer? _debounce;

  UserFeedback? _item;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _service.subscribe(
      feedbackId: widget.feedbackId,
      onChange: () {
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 400),
          () => _load(silent: true),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _service.unsubscribe(_channel);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final item = await _service.fetchById(widget.feedbackId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _item == null;
      });
    }
  }

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) {
                        AppToast.error('Could not load the image.');
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _item;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SettingsDetailSliverAppBar(
            icon: item?.category.icon ?? CupertinoIcons.chat_bubble_text_fill,
            title: item == null ? 'Feedback' : 'Feedback #${item.shortId}',
            subtitle: item?.category.label ?? 'Support conversation',
          ),
          if (_loading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverToBoxAdapter(child: FeedbackDetailsSkeleton()),
            )
          else if (item == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _failed
                          ? 'Could not load this feedback.'
                          : 'This feedback is no longer available.',
                    ),
                    if (_failed)
                      TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([_buildBody(context, item)]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserFeedback item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : Colors.black54;
    final fmt = DateFormat('MMM d, y · h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FeedbackStatusChip(status: item.status),
            const Gap(10),
            Expanded(
              child: Text(
                'Sent ${fmt.format(item.createdAt)}',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
        if (item.status == FeedbackStatus.pending) ...[
          const Gap(12),
          const SettingsInfoBanner(
            icon: CupertinoIcons.clock,
            message: 'Response within 24 hours (max 3 days).',
          ),
        ],
        const Gap(18),
        SettingsSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your message',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              if (item.rating != null) ...[
                const Gap(8),
                FeedbackStarRatingBar(
                  value: item.rating,
                  onChanged: (_) {},
                  size: 20,
                  readOnly: true,
                ),
              ],
              const Gap(10),
              SelectableText(
                item.message,
                style: const TextStyle(height: 1.5, fontSize: 14.5),
              ),
              if (item.imageUrl != null) ...[
                const Gap(14),
                GestureDetector(
                  onTap: () => _openImage(item.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => const SizedBox(
                            height: 180,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (_, __, ___) => const SizedBox(
                            height: 80,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                    ),
                  ),
                ),
              ],
              if (item.audioUrl != null) ...[
                const Gap(14),
                CommentVoicePlayer(
                  source: item.audioUrl!,
                  durationSeconds: item.audioDurationSeconds,
                ),
              ],
            ],
          ),
        ),
        const Gap(16),
        if (item.hasReply)
          _ReplyCard(response: item.adminResponse!, at: item.respondedAt)
        else if (item.status == FeedbackStatus.resolved ||
            item.status == FeedbackStatus.closed)
          const SettingsInfoBanner(
            icon: CupertinoIcons.checkmark_seal_fill,
            tone: SettingsBannerTone.success,
            message:
                'Our team has reviewed this feedback. Thank you for helping us improve!',
          )
        else if (item.status == FeedbackStatus.inProgress)
          const SettingsInfoBanner(
            icon: CupertinoIcons.hammer_fill,
            message:
                'We are working on this. You will be notified when we reply.',
          ),
      ],
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final String response;
  final DateTime? at;
  const _ReplyCard({required this.response, this.at});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF27AE60);

    return SettingsSurfaceCard(
      accent: green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.headphones,
                            color: Colors.white,
                            size: 9.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Social Mate Support',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Gap(4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF1D9BF0),
                          size: 16,
                        ),
                      ],
                    ),
                    if (at != null) ...[
                      const Gap(2),
                      Text(
                        DateFormat('MMM d, y · h:mm a').format(at!),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 12,
                      color: green,
                    ),
                    Gap(4),
                    Text(
                      'Official',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          SelectableText(
            response,
            style: const TextStyle(height: 1.5, fontSize: 14.5),
          ),
        ],
      ),
    );
  }
}
