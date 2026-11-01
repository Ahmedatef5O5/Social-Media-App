import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import '../../../core/chat_shared/cubits/shared_media_cubit/shared_media_cubit.dart';
import '../../../core/chat_shared/services/shared_media_data_source.dart';
import '../../../core/design/components/app_bottom_sheet.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/media_editor/media_editor_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../posts/services/posts_services.dart';
import '../cubits/group_feed_cubit/group_feed_cubit.dart';
import '../cubits/group_list_cubit/group_list_cubit.dart';
import '../cubits/group_members_cubit/group_members_cubit.dart';
import '../cubits/group_profile_cubit/group_profile_cubit.dart';
import '../helpers/group_navigation.dart';
import '../helpers/group_role_resolver.dart';
import '../models/group_profile_model.dart';
import '../models/group_view_args.dart';
import '../services/group_chat_services.dart';
import '../widgets/group_details_tab.dart';
import '../widgets/group_invite_link_section.dart';
import '../widgets/group_join_requests_sheet.dart';
import '../widgets/group_members_tab.dart';
import '../widgets/group_posts_tab.dart';
import '../widgets/group_view_header.dart';
import 'add_group_members_view.dart';
import 'group_settings_view.dart';

/// Group profile (Facebook-Groups style): cover, avatar, stats, quick actions
/// and Posts / Members / Details tabs. A non-member never sees this screen's
/// content: they are redirected to [GroupPreviewJoinView].
///
/// Requires a [GroupProfileCubit] above it (provided by the router).
class GroupView extends StatelessWidget {
  final GroupViewArgs args;
  const GroupView({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupProfileCubit, GroupProfileState>(
      listenWhen:
          (prev, cur) => cur is GroupProfileLoaded && !cur.profile.isMember,
      listener: (context, state) {
        // Not (or no longer) a member -> preview / join page.
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.groupPreviewJoinViewRoute,
          arguments: args,
        );
      },
      builder: (context, state) {
        if (state is GroupProfileLoaded && state.profile.isMember) {
          return _GroupViewBody(
            key: ValueKey(state.profile.id),
            initial: state.profile,
          );
        }
        if (state is GroupProfileError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  TextButton(
                    onPressed: () => context.read<GroupProfileCubit>().load(),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is GroupProfileNotFound) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: Center(child: Text(context.l10n.groupNotFound)),
          );
        }
        return const _GroupViewShimmer();
      },
    );
  }
}

class _GroupViewBody extends StatefulWidget {
  final GroupProfileModel initial;
  const _GroupViewBody({super.key, required this.initial});

  @override
  State<_GroupViewBody> createState() => _GroupViewBodyState();
}

class _GroupViewBodyState extends State<_GroupViewBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final GroupChatServices _services;
  late final GroupMembersCubit _membersCubit;
  late final GroupFeedCubit _feedCubit;
  late final SharedMediaCubit _mediaCubit;
  late final PostsCubit _postsCubit;
  late final GroupProfileCubit _profileCubit;
  late final String _groupId;

  bool _uploadingCover = false;
  bool _uploadingAvatar = false;
  bool _wasInList = false;
  bool _evicted = false;

  String get _myId => SupabaseProvider.id;

  @override
  void initState() {
    super.initState();
    _groupId = widget.initial.id;
    _tabs = TabController(length: 3, vsync: this);
    _services = context.read<GroupChatServices>();
    _postsCubit = context.read<PostsCubit>();
    _profileCubit = context.read<GroupProfileCubit>();
    _membersCubit = GroupMembersCubit(_services, groupId: _groupId)
      ..loadMembers();
    _feedCubit = GroupFeedCubit(
      groupId: _groupId,
      postsServices: context.read<PostsServices>(),
      postsCubit: _postsCubit,
    )..loadInitial();
    _mediaCubit = SharedMediaCubit(
      GroupChatMediaDataSource(services: _services, groupId: _groupId),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _membersCubit.close();
    _feedCubit.close();
    _mediaCubit.close();
    super.dispose();
  }

  // ── Eviction (left / removed / blocked / group deleted) ─────────────────
  void _onGroupListChanged(GroupListState state) {
    if (state is! GroupListLoaded || _evicted) return;
    final live = state.groups.where((g) => g.id == _groupId);
    if (live.isNotEmpty && live.first.isMember && !live.first.isBlocked) {
      _wasInList = true;
      return;
    }
    // Only evict once we have actually seen the group in the list, so a stale
    // snapshot right after joining can never kick a legitimate member out.
    if (!_wasInList) return;
    _evict();
  }

  void _evict() {
    if (_evicted) return;
    _evicted = true;
    _feedCubit.evict(); // also purges the shared feed cache
    GroupRoleResolver.invalidate(_groupId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil(
      (r) => r.isFirst || r.settings.name == AppRoutes.yourGroupsRoute,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  void _openChat(GroupProfileModel p) {
    openGroupChat(
      p.id,
      () => Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.groupChatRoute, arguments: p.toGroupModel()),
    );
  }

  void _openInvite(GroupProfileModel p) {
    AppBottomSheet.show<void>(
      context: context,
      builder:
          (_) => AppBottomSheet(
            title: context.l10n.groupActionInvite,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GroupInviteLinkSection(
                groupId: p.id,
                groupName: p.name,
                services: _services,
              ),
            ),
          ),
    );
  }

  void _openSettings(GroupProfileModel p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => GroupSettingsView(
              group: p.toGroupModel(),
              membersCubit: _membersCubit,
              groupListCubit: context.read<GroupListCubit>(),
              isAdmin: p.hasAdminPrivileges,
              isOwner: p.isOwner,
              currentUserId: _myId,
              profileCubit: _profileCubit,
            ),
      ),
    );
  }

  void _openAddMembers() {
    final state = _membersCubit.state;
    final existing =
        state is GroupMembersLoaded
            ? state.members.map((m) => m.userId).toSet()
            : <String>{};
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddGroupMembersView(
              membersCubit: _membersCubit,
              existingMemberIds: existing,
              currentUserId: _myId,
            ),
      ),
    );
  }

  Future<void> _newPost(GroupProfileModel p) async {
    if (!p.canPost) return;
    await Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.createPostViewRoute,
      arguments: {'cubit': _postsCubit, 'targetGroup': p.toGroupModel()},
    );
    if (mounted) _profileCubit.load(silent: true); // refresh counters
  }

  void _openPendingRequests() {
    GroupJoinRequestsSheet.show(
      context,
      groupId: _groupId,
      onReviewed: () {
        _profileCubit.load(silent: true); // member count + pending count
        _membersCubit.refresh();
      },
    );
  }

  Future<File?> _pickImage({required MediaEditorPreset preset}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return null;
    final edited = await MediaEditorService.editImage(
      context,
      File(picked.path),
      preset: preset,
    );
    return edited ?? File(picked.path);
  }

  Future<void> _changeCover() async {
    final file = await _pickImage(preset: MediaEditorPreset.post);
    if (file == null || !mounted) return;
    setState(() => _uploadingCover = true);
    try {
      await _profileCubit.changeCover(file);
      if (mounted) AppToast.success(context.l10n.groupCoverUpdated);
    } catch (e) {
      if (mounted) AppToast.error(context.l10n.failedToUpdateGroup);
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _changeAvatar(GroupProfileModel p) async {
    final file = await _pickImage(preset: MediaEditorPreset.avatar);
    if (file == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final result = await _services.uploadGroupAvatar(file);
      await _services.updateGroupAvatarUrl(
        p.id,
        result.secureUrl,
        result.publicId,
      );
      if (!mounted) return;
      context.read<GroupListCubit>().updateGroupAvatar(
        groupId: p.id,
        newAvatarUrl: result.secureUrl,
      );
      if (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(p.avatarUrl!);
      }
      _profileCubit.applyLocal(avatarUrl: result.secureUrl);
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top; // before removePadding

    return MultiBlocProvider(
      providers: [BlocProvider.value(value: _feedCubit)],
      child: BlocListener<GroupListCubit, GroupListState>(
        listener: (_, state) => _onGroupListChanged(state),
        child: BlocBuilder<GroupProfileCubit, GroupProfileState>(
          buildWhen: (_, cur) => cur is GroupProfileLoaded,
          builder: (context, state) {
            final p =
                state is GroupProfileLoaded ? state.profile : widget.initial;

            return Scaffold(
              body: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: NestedScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  headerSliverBuilder:
                      (context, _) => [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              GroupViewHeader(
                                profile: p,
                                topInset: topInset,
                                isUploadingCover: _uploadingCover,
                                isUploadingAvatar: _uploadingAvatar,
                                onBack: () => Navigator.of(context).maybePop(),
                                onEditCover:
                                    p.hasAdminPrivileges ? _changeCover : null,
                                onEditAvatar:
                                    p.hasAdminPrivileges
                                        ? () => _changeAvatar(p)
                                        : null,
                              ),
                              GroupQuickActions(
                                profile: p,
                                onChat: () => _openChat(p),
                                onInvite: () => _openInvite(p),
                                onSettings: () => _openSettings(p),
                                onNewPost: () => _newPost(p),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned:
                              false, // like ProfileView: tabs scroll with the header
                          delegate: _TabsDelegate(
                            color: theme.scaffoldBackgroundColor,
                            tabBar: TabBar(
                              controller: _tabs,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 3,
                              dividerColor: theme.dividerColor,
                              tabs: [
                                Tab(text: context.l10n.posts),
                                Tab(text: context.l10n.members),
                                Tab(text: context.l10n.groupDetailsAndMedia),
                              ],
                            ),
                          ),
                        ),
                      ],
                  body: TabBarView(
                    controller: _tabs,
                    children: [
                      GroupPostsTab(
                        profile: p,
                        postsCubit: _postsCubit,
                        onNewPost: () => _newPost(p),
                      ),
                      GroupMembersTab(
                        profile: p,
                        membersCubit: _membersCubit,
                        currentUserId: _myId,
                        onOpenPendingRequests: _openPendingRequests,
                        onAddMembers: _openAddMembers,
                      ),
                      GroupDetailsTab(
                        profile: p,
                        mediaCubit: _mediaCubit,
                        onShowInChat: (sheetContext, _) {
                          Navigator.of(sheetContext).pop();
                          _openChat(p);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  _TabsDelegate({required this.tabBar, required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(color: color, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.tabBar != tabBar || old.color != color;
}

class _GroupViewShimmer extends StatelessWidget {
  const _GroupViewShimmer();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final double coverHeight = size.width / 1.7;
    const double avatarSize = 92;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: coverHeight + avatarSize / 2 + 8,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: coverHeight,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 0,
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (_) => Column(
                      children: [
                        Container(
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Gap(6),
                        Container(
                          width: 48,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (_) => Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(8),
                      Container(
                        width: 50,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
