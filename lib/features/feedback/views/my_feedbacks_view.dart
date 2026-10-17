import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/settings/widgets/settings_detail_sliver_app_bar.dart';
import 'package:social_media_app/features/settings/widgets/settings_surface_card.dart';
import '../cubits/feedback_cubit.dart';
import '../cubits/feedback_state.dart';
import '../models/feedback_models.dart';
import '../widgets/feedback_skeletons.dart';
import '../widgets/feedback_star_rating_bar.dart';
import '../widgets/feedback_status_chip.dart';

class MyFeedbacksView extends StatelessWidget {
  const MyFeedbacksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<FeedbackCubit>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await cubit.refreshHistory(silent: true);
          await cubit.refreshQuota();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            const SettingsDetailSliverAppBar(
              icon: CupertinoIcons.tray_full_fill,
              title: 'My Feedbacks',
              subtitle: 'Track the status of your submissions',
            ),
            BlocBuilder<FeedbackCubit, FeedbackState>(
              buildWhen:
                  (p, c) =>
                      p.history != c.history ||
                      p.historyLoading != c.historyLoading ||
                      p.historyFailed != c.historyFailed,
              builder: (context, state) {
                if (state.historyLoading && state.history.isEmpty) {
                  return const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverToBoxAdapter(child: FeedbackListSkeleton()),
                  );
                }
                if (state.historyFailed && state.history.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: CupertinoIcons.wifi_exclamationmark,
                      title: 'Could not load your feedbacks',
                      action: TextButton(
                        onPressed: cubit.refreshHistory,
                        child: const Text('Retry'),
                      ),
                    ),
                  );
                }
                if (state.history.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: CupertinoIcons.chat_bubble_text,
                      title: 'No feedback yet',
                      subtitle:
                          'Anything you send us will show up here with its status.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: state.history.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder:
                        (context, i) => _FeedbackTile(item: state.history[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final UserFeedback item;
  const _FeedbackTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : Colors.black54;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap:
          () => Navigator.of(
            context,
          ).pushNamed(AppRoutes.feedbackDetailsRoute, arguments: item.id),
      child: SettingsSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.category.icon,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    item.category.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                FeedbackStatusChip(status: item.status, compact: true),
              ],
            ),
            const Gap(10),
            Text(
              item.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (item.rating != null) ...[
              const Gap(8),
              FeedbackStarRatingBar(
                value: item.rating,
                onChanged: (_) {},
                size: 16,
                readOnly: true,
              ),
            ],
            const Gap(10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${item.shortId} · ${DateFormat('MMM d, y · h:mm a').format(item.createdAt)}',
                    style: TextStyle(fontSize: 11.5, color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.hasReply) ...[
                  const Gap(8),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.reply,
                        size: 13,
                        color: Color(0xFF27AE60),
                      ),
                      Gap(4),
                      Text(
                        'Reply received',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (item.status == FeedbackStatus.pending && !item.hasReply) ...[
              const Gap(6),
              Row(
                children: [
                  Icon(CupertinoIcons.clock, size: 11.5, color: muted),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      'Response within 24 hours (max 3 days)',
                      style: TextStyle(fontSize: 11, color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: isDark ? Colors.white30 : Colors.black26),
          const Gap(14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (subtitle != null) ...[
            const Gap(6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
          if (action != null) ...[const Gap(8), action!],
        ],
      ),
    );
  }
}
