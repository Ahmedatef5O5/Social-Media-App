import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../helpers/group_profile_navigation.dart';
import '../models/group_model.dart';
import '../services/group_social_service.dart';
import '../widgets/group_square_avatar.dart';

/// "Your Groups": every group the user is an active member of. Tapping a tile
/// opens the group's profile (GroupView).
class YourGroupsView extends StatefulWidget {
  const YourGroupsView({super.key});

  @override
  State<YourGroupsView> createState() => _YourGroupsViewState();
}

class _YourGroupsViewState extends State<YourGroupsView> {
  final _searchController = TextEditingController();
  final _social = GroupSocialService();
  String _query = '';
  Map<String, int> _memberCounts = const {};
  String _countsKey = '';

  @override
  void initState() {
    super.initState();
    final cubit = context.read<GroupListCubit>();
    if (cubit.state is GroupListInitial) cubit.loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCounts(List<GroupModel> groups) async {
    final ids = groups.map((g) => g.id).toList()..sort();
    final key = ids.join(',');
    if (key == _countsKey) return;
    _countsKey = key;
    final counts = await _social.getMemberCounts(ids);
    if (mounted) setState(() => _memberCounts = counts);
  }

  List<GroupModel> _visible(List<GroupModel> all) {
    final q = _query.trim().toLowerCase();
    final mine = all.where((g) => g.isMember && !g.isBlocked);
    final filtered =
        q.isEmpty
            ? mine
            : mine.where(
              (g) =>
                  g.name.toLowerCase().contains(q) ||
                  (g.title ?? '').toLowerCase().contains(q),
            );
    final list = filtered.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          context.l10n.yourGroups,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.createGroup,
            icon: const Icon(Icons.group_add_rounded),
            onPressed:
                () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.createGroupRoute),
          ),
          const Gap(4),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchYourGroups,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<GroupListCubit, GroupListState>(
              listener: (context, state) {
                if (state is GroupListLoaded) _loadCounts(state.groups);
              },
              builder: (context, state) {
                if (state is GroupListError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message),
                        CupertinoButton(
                          onPressed:
                              () => context.read<GroupListCubit>().loadGroups(),
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                if (state is! GroupListLoaded) {
                  return const _YourGroupsShimmer();
                }
                final groups = _visible(state.groups);
                if (groups.isEmpty) return _Empty(isSearch: _query.isNotEmpty);

                return RefreshIndicator(
                  onRefresh:
                      () => context.read<GroupListCubit>().loadGroups(
                        isRefresh: true,
                      ),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, i) {
                      final g = groups[i];
                      return _GroupTile(
                        group: g,
                        membersCount: _memberCounts[g.id],
                        onTap:
                            () => openGroupProfile(
                              context,
                              groupId: g.id,
                              group: g,
                            ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupModel group;
  final int? membersCount;
  final VoidCallback onTap;

  const _GroupTile({
    required this.group,
    required this.membersCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitleParts = <String>[
      if (membersCount != null) context.l10n.membersCountLabel(membersCount!),
      if (group.title?.trim().isNotEmpty == true) group.title!.trim(),
    ];

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              GroupSquareAvatar(url: group.avatarUrl, size: 54, radius: 16),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: context.ls(0),
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const Gap(3),
                      Text(
                        subtitleParts.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: muted,
                          letterSpacing: context.ls(0),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (group.unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: group.isMuted ? muted : theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Gap(4),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isSearch;
  const _Empty({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyFindingsThemedAnimation(
              animationPath: AppImages.emptyFindingsLot,
              width: 150,
              height: 150,
            ),
            const Gap(8),
            Text(
              isSearch ? context.l10n.noResultsFound : context.l10n.noGroupsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourGroupsShimmer extends StatelessWidget {
  const _YourGroupsShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (_, index) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: index.isEven ? 130 : 160,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Gap(8),
                      Container(
                        width: index.isEven ? 80 : 110,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
