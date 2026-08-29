import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_media_app/core/widgets/full_screen_image_viewer.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/deep_link/services/deep_link_service.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/toast/app_toast.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';
import '../cubit/group_members_cubit/group_members_cubit.dart';
import '../helpers/group_info_action_btn_widget.dart';
import '../helpers/invite_link_section_skeleton.dart';
import '../models/group_invite_state.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../services/group_chat_services.dart';

class GroupSettingsView extends StatefulWidget {
  final GroupModel group;
  final GroupMembersCubit membersCubit;
  final GroupListCubit groupListCubit;
  final GroupDetailsCubit? detailsCubit;
  final bool isAdmin;
  final bool isOwner;
  final String currentUserId;

  const GroupSettingsView({
    super.key,
    required this.group,
    required this.membersCubit,
    required this.groupListCubit,
    this.detailsCubit,
    required this.isAdmin,
    required this.isOwner,
    required this.currentUserId,
  });

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  late final GroupChatServices _services;

  late final TextEditingController _nameController;
  late final TextEditingController _titleController;

  bool _isSavingName = false;
  bool _isSavingTitle = false;
  String? _currentAvatarUrl;

  bool _isUploadingPhoto = false;
  bool _isRemovingPhoto = false;
  GroupInviteState? _inviteState;
  bool _isLoadingInvite = true;
  bool _isUpdatingInvite = false;
  Timer? _inviteBadgeTimer;

  @override
  void initState() {
    super.initState();
    _services = context.read<GroupChatServices>();
    _nameController = TextEditingController(text: widget.group.name);
    _titleController = TextEditingController(text: widget.group.title ?? '');
    _currentAvatarUrl = widget.group.avatarUrl;

    if (widget.membersCubit.state is! GroupMembersLoaded) {
      widget.membersCubit.loadMembers();
    }

    if (widget.isAdmin || widget.isOwner) {
      if (_services.hasCachedInviteState(widget.group.id)) {
        _inviteState = _services.getCachedInviteState(widget.group.id);
        _isLoadingInvite = false;
        _refreshInviteStateSilently();
      } else {
        _loadInviteState();
      }
    } else {
      _isLoadingInvite = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _inviteBadgeTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.group.name) return;

    setState(() => _isSavingName = true);

    try {
      await _services.updateGroup(groupId: widget.group.id, name: newName);
      widget.groupListCubit.updateGroupName(
        groupId: widget.group.id,
        newName: newName,
      );
      if (mounted) AppToast.success('Group name updated');
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle == (widget.group.title ?? '')) return;

    setState(() => _isSavingTitle = true);
    try {
      final value = newTitle.isEmpty ? null : newTitle;
      await _services.updateGroupTitle(widget.group.id, value);
      widget.groupListCubit.updateGroupTitle(
        groupId: widget.group.id,
        newTitle: value,
      );
      if (mounted) AppToast.success('Group title updated');
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _isSavingTitle = false);
    }
  }

  String _inviteUrlFor(String hash) =>
      'https://${DeepLinkService.host}/join/$hash';

  Future<void> _refreshInviteStateSilently() async {
    try {
      final state = await _services.getGroupInviteState(widget.group.id);
      if (mounted && state != _inviteState) {
        setState(() => _inviteState = state);
        _restartBadgeTimerIfNeeded();
      }
    } catch (_) {
      // Silent by design — the cached value stays on screen; explicit
      // actions (Generate/Revoke) still surface their own errors.
    }
  }

  Future<void> _loadInviteState() async {
    try {
      final state = await _services.getGroupInviteState(widget.group.id);
      if (mounted) {
        setState(() {
          _inviteState = state;
          _isLoadingInvite = false;
        });
        _restartBadgeTimerIfNeeded();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInvite = false);
    }
  }

  void _restartBadgeTimerIfNeeded() {
    _inviteBadgeTimer?.cancel();
    if (_inviteState?.expiresAt != null) {
      // Only the displayed countdown text needs refreshing — no network
      // call — so a cheap 60s tick is enough, no need for per-second.
      _inviteBadgeTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<_InviteExpiryChoice?> _pickInviteExpiryDuration() {
    return showDialog<_InviteExpiryChoice>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Link Expiration'),
            children: [
              SimpleDialogOption(
                onPressed:
                    () =>
                        Navigator.pop(context, const _InviteExpiryChoice(null)),
                child: const Text('Never expires'),
              ),
              SimpleDialogOption(
                onPressed:
                    () => Navigator.pop(
                      context,
                      const _InviteExpiryChoice(Duration(hours: 24)),
                    ),
                child: const Text('24 hours'),
              ),
              SimpleDialogOption(
                onPressed:
                    () => Navigator.pop(
                      context,
                      const _InviteExpiryChoice(Duration(days: 2)),
                    ),
                child: const Text('2 days'),
              ),
              SimpleDialogOption(
                onPressed:
                    () => Navigator.pop(
                      context,
                      const _InviteExpiryChoice(Duration(days: 7)),
                    ),
                child: const Text('1 week'),
              ),
            ],
          ),
    );
  }

  Future<void> _generateInviteLink() async {
    final choice = await _pickInviteExpiryDuration();
    if (choice == null) return; // user dismissed the picker
    if (!mounted) return;
    setState(() => _isUpdatingInvite = true);
    try {
      final state = await _services.generateGroupInviteLink(
        widget.group.id,
        expiresIn: choice.duration,
      );
      if (mounted) {
        setState(() {
          _inviteState = state;
          _isUpdatingInvite = false;
        });
        _restartBadgeTimerIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingInvite = false);
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    }
  }

  Future<void> _revokeInviteLink() async {
    final confirm = await _confirm(
      context,
      title: 'Revoke Invite Link',
      body:
          'Anyone with the current link will no longer be able to join using it. Continue?',
      confirmLabel: 'Revoke',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isUpdatingInvite = true);
    try {
      await _services.revokeGroupInviteLink(widget.group.id);
      if (mounted) {
        _inviteBadgeTimer?.cancel();
        setState(() {
          _inviteState = null;
          _isUpdatingInvite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingInvite = false);
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    }
  }

  void _copyInviteLink() {
    final hash = _inviteState?.inviteHash;
    if (hash == null) return;
    Clipboard.setData(ClipboardData(text: _inviteUrlFor(hash)));
    AppToast.success('Invite link copied');
  }

  void _forwardInviteLink() {
    final hash = _inviteState?.inviteHash;
    if (hash == null) return;
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join "${widget.group.name}" on Social Media App: ${_inviteUrlFor(hash)}',
        sharePositionOrigin:
            box != null ? (box.localToGlobal(Offset.zero) & box.size) : null,
      ),
    );
  }

  String? _expiryBadgeText() {
    final expiresAt = _inviteState?.expiresAt;
    if (expiresAt == null) return null;

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays >= 1) {
      return 'Expires in ${remaining.inDays}d ${remaining.inHours.remainder(24)}h';
    }
    if (remaining.inHours >= 1) {
      return 'Expires in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    }
    return 'Expires in ${remaining.inMinutes}m';
  }

  Widget _buildGenerateInviteRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Create a link to let others join this group.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
          ),
        ),
        const SizedBox(width: 12),
        _isUpdatingInvite
            ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : TextButton(
              onPressed: _generateInviteLink,
              child: const Text('Generate'),
            ),
      ],
    );
  }

  Widget _buildActiveInviteRow(GroupInviteState state) {
    final badgeText = _expiryBadgeText();
    final isExpired = badgeText == 'Expired';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _inviteUrlFor(state.inviteHash),
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        if (state.joinCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${state.joinCount} joined via this link',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUpdatingInvite ? null : _copyInviteLink,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUpdatingInvite ? null : _forwardInviteLink,
                icon: const Icon(Icons.forward_rounded, size: 18),
                label: const Text('Forward'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (isExpired ? Colors.red : Colors.orange).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isExpired ? Colors.red : Colors.orange).withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isExpired ? Colors.red : Colors.orange.shade800,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            TextButton.icon(
              onPressed: _isUpdatingInvite ? null : _revokeInviteLink,
              icon: const Icon(
                Icons.link_off_rounded,
                size: 18,
                color: Colors.red,
              ),
              label: const Text(
                'Revoke Link',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final result = await _services.uploadGroupAvatar(File(picked.path));
      await _services.updateGroupAvatarUrl(
        widget.group.id,
        result.secureUrl,
        result.publicId,
      );
      widget.groupListCubit.updateGroupAvatar(
        groupId: widget.group.id,
        newAvatarUrl: result.secureUrl,
      );
      if (mounted) {
        setState(() => _currentAvatarUrl = result.secureUrl);
        if (widget.group.avatarUrl != null &&
            widget.group.avatarUrl!.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(widget.group.avatarUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(SupabaseErrorMapper.toUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirm = await _confirm(
      context,
      title: 'Remove Group Photo',
      body: 'This will remove the current group photo for everyone.',
      confirmLabel: 'Remove',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isRemovingPhoto = true);

    try {
      await _services.removeGroupAvatar(widget.group.id);
      widget.groupListCubit.clearGroupAvatar(widget.group.id);
      if (mounted) {
        setState(() => _currentAvatarUrl = null);
        AppToast.success('Group photo removed');
      }
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _isRemovingPhoto = false);
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel,
                  style: TextStyle(color: confirmColor),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await _confirm(
      context,
      title: 'Leave Group',
      body: 'Are you sure you want to leave "${liveGroup.name}"?',
      confirmLabel: 'Leave',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await widget.membersCubit.leaveGroup(
        currentUserId: widget.currentUserId,
        groupListCubit: widget.groupListCubit,
      );
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (context.mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _blockGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await _confirm(
      context,
      title: 'Block Group',
      body:
          liveGroup.isMember
              ? 'You will leave "${liveGroup.name}", the chat history on this device will be cleared, and you won\'t be able to be re-added to this group. Continue?'
              : 'The chat history on this device will be cleared, and you won\'t be able to be re-added to this group. Continue?',
      confirmLabel: 'Block',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await widget.membersCubit.blockGroup(
        currentUserId: widget.currentUserId,
        groupListCubit: widget.groupListCubit,
        isCurrentlyMember: liveGroup.isMember,
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _deleteGroup(BuildContext context, GroupModel liveGroup) async {
    final confirm = await _confirm(
      context,
      title: 'Delete Group',
      body:
          'This will permanently delete "${liveGroup.name}" for you and '
          'every member — all messages, media, and members will be '
          'removed. This cannot be undone. Continue?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;
    try {
      await widget.membersCubit.deleteGroup(
        currentUserId: widget.currentUserId,
        groupListCubit: widget.groupListCubit,
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _handleAdminAction(
    BuildContext context,
    GroupMemberModel admin,
    String action,
  ) async {
    try {
      if (action == 'demote') {
        await widget.membersCubit.demoteAdmin(
          admin,
          currentUserId: widget.currentUserId,
        );
        if (mounted) {
          AppToast.success('${admin.userName} is no longer an admin');
        }
      } else if (action == 'remove') {
        final confirm = await _confirm(
          context,
          title: 'Remove Member',
          body: 'Remove ${admin.userName} from the group?',
          confirmLabel: 'Remove',
          confirmColor: Colors.red,
        );
        if (confirm != true) return;
        await widget.membersCubit.removeMember(
          admin,
          currentUserId: widget.currentUserId,
        );
        if (mounted) {
          AppToast.success('${admin.userName} removed from the group');
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  void _openFullScreenAvatar(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const FullScreenImageViewer(),
        settings: RouteSettings(
          arguments: {
            'url': widget.group.avatarUrl ?? AppImages.defaultGroupImg,
            'tag': 'group-avatar-${widget.group.id}',
            'isAsset': _currentAvatarUrl != null ? false : true,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsCubit = widget.detailsCubit;
    if (detailsCubit != null) {
      return BlocBuilder<GroupDetailsCubit, GroupDetailsState>(
        bloc: detailsCubit,
        builder: (context, detailsState) {
          final isMemberLive =
              detailsState is GroupDetailsLoaded
                  ? detailsState.isMember
                  : widget.group.isMember;
          return _buildBody(context, isMemberOverride: isMemberLive);
        },
      );
    }
    return _buildBody(context, isMemberOverride: null);
  }

  Widget _buildBody(BuildContext context, {required bool? isMemberOverride}) {
    final primary = Theme.of(context).primaryColor;

    return BlocBuilder<GroupListCubit, GroupListState>(
      bloc: widget.groupListCubit,
      builder: (context, listState) {
        final liveGroup =
            (listState is GroupListLoaded)
                ? listState.groups.firstWhere(
                  (g) => g.id == widget.group.id,
                  orElse: () => widget.group,
                )
                : widget.group;
        final isMember = isMemberOverride ?? liveGroup.isMember;

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text(
                    'Group Settings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  centerTitle: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  pinned: false,
                  floating: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  sliver: SliverList.list(
                    children: [
                      if (widget.isAdmin) ...[
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => _openFullScreenAvatar(context),
                                child: Hero(
                                  tag: 'group-avatar-${widget.group.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primary.withValues(alpha: 0.185),
                                        width: 5.5,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 72,
                                      backgroundColor: AppColors.black12,
                                      backgroundImage:
                                          _currentAvatarUrl != null
                                              ? CachedNetworkImageProvider(
                                                _currentAvatarUrl!,
                                              )
                                              : null,
                                      child:
                                          _currentAvatarUrl == null
                                              ? Container(
                                                padding: EdgeInsets.zero,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: AssetImage(
                                                      AppImages.defaultGroupImg,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                              // Icon(
                                              //   Icons.group,
                                              //   size: 72,
                                              //   color: Colors.grey.shade400,
                                              // )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: GestureDetector(
                                  onTap:
                                      _isUploadingPhoto ? null : _changePhoto,
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(
                                            alpha: 0.85,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  ScaleTransition(
                                                    scale: animation,
                                                    child: FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                                  ),
                                          child:
                                              _isUploadingPhoto
                                                  ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Icon(
                                                    Icons.camera_alt_rounded,
                                                    key: ValueKey(
                                                      'camera_icon',
                                                    ),
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (_currentAvatarUrl != null &&
                                  _currentAvatarUrl!.isNotEmpty)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap:
                                        _isRemovingPhoto ? null : _removePhoto,
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 12,
                                          sigmaY: 12,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade500
                                                .withValues(alpha: 0.85),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            transitionBuilder:
                                                (child, animation) =>
                                                    ScaleTransition(
                                                      scale: animation,
                                                      child: FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      ),
                                                    ),
                                            child:
                                                _isRemovingPhoto
                                                    ? const SizedBox(
                                                      key: ValueKey(
                                                        'loading_remove',
                                                      ),
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      key: ValueKey(
                                                        'delete_icon',
                                                      ),
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Live Group Name & Title Preview ---
                        Center(
                          child: Text(
                            liveGroup.name,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: AnimatedBuilder(
                            animation: _titleController,
                            builder: (context, _) {
                              final titleText = _titleController.text.trim();
                              if (titleText.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                titleText,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // في build() — ضيف القسم ده فوق "Group Title Section" مباشرة (نفس الـ styling تمامًا)
                        // --- Group Name Section ---
                        Text(
                          'Group Name',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _nameController,
                          builder: (context, _) {
                            final currentText = _nameController.text.trim();
                            final isChanged =
                                currentText.isNotEmpty &&
                                currentText != widget.group.name;

                            return TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Group name',
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 1.5,
                                  ),
                                ),
                                suffixIcon:
                                    _isSavingName
                                        ? const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                        : IconButton(
                                          icon: Icon(
                                            Icons.check_circle,
                                            color:
                                                isChanged
                                                    ? primary
                                                    : Colors.grey.shade300,
                                          ),
                                          onPressed:
                                              isChanged ? _saveName : null,
                                          tooltip: 'Save Name',
                                        ),
                              ),
                              onSubmitted:
                                  isChanged ? (_) => _saveName() : null,
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- Group Title Section ---
                        Text(
                          'Group Title',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _titleController,
                          builder: (context, _) {
                            final currentText = _titleController.text.trim();
                            final isChanged =
                                currentText != (widget.group.title ?? '');

                            return TextField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a title for this group',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 1.5,
                                  ),
                                ),
                                suffixIcon:
                                    _isSavingTitle
                                        ? const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                        : IconButton(
                                          icon: Icon(
                                            Icons.check_circle,
                                            color:
                                                isChanged
                                                    ? primary
                                                    : Colors.grey.shade300,
                                          ),
                                          onPressed:
                                              isChanged ? _saveTitle : null,
                                          tooltip: 'Save Title',
                                        ),
                              ),
                              onSubmitted:
                                  isChanged ? (_) => _saveTitle() : null,
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // --- Group Owner Section ---
                        BlocBuilder<GroupMembersCubit, GroupMembersState>(
                          bloc: widget.membersCubit,
                          builder: (context, memberState) {
                            GroupMemberModel? owner;
                            if (memberState is GroupMembersLoaded) {
                              for (final m in memberState.members) {
                                if (m.role == GroupMemberRole.owner) {
                                  owner = m;
                                  break;
                                }
                              }
                            }
                            if (owner == null) return const SizedBox.shrink();

                            final isMe = owner.userId == widget.currentUserId;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Owner',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage:
                                          owner.userAvatar != null
                                              ? CachedNetworkImageProvider(
                                                owner.userAvatar!,
                                              )
                                              : null,
                                      child:
                                          owner.userAvatar == null
                                              ? Icon(
                                                Icons.person,
                                                color: Colors.grey.shade400,
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      isMe ? 'You' : owner.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 13,
                                            color: Colors.amber,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Owner',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),

                        // --- Group Admins Section ---
                        BlocBuilder<GroupMembersCubit, GroupMembersState>(
                          bloc: widget.membersCubit,
                          builder: (context, memberState) {
                            List<GroupMemberModel> admins = [];

                            if (memberState is GroupMembersLoaded) {
                              admins =
                                  memberState.members
                                      .where(
                                        (m) => m.role == GroupMemberRole.admin,
                                      )
                                      .toList();
                            }

                            if (admins.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Admins',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    itemCount: admins.length,
                                    // separatorBuilder:
                                    //     (_, __) => const Divider(
                                    //       height: 1,
                                    //       indent: 64,
                                    //     ),
                                    itemBuilder: (context, index) {
                                      final admin = admins[index];
                                      final isMe =
                                          admin.userId == widget.currentUserId;

                                      return ListTile(
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage:
                                              admin.userAvatar != null
                                                  ? CachedNetworkImageProvider(
                                                    admin.userAvatar!,
                                                  )
                                                  : null,
                                          child:
                                              admin.userAvatar == null
                                                  ? Icon(
                                                    Icons.person,
                                                    color: Colors.grey.shade400,
                                                  )
                                                  : null,
                                        ),
                                        title: Text(
                                          isMe ? 'You' : admin.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primary.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Admin',
                                                style: TextStyle(
                                                  color: primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (widget.isOwner) ...[
                                              const SizedBox(width: 2),
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.more_vert_rounded,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                onSelected:
                                                    (value) =>
                                                        _handleAdminAction(
                                                          context,
                                                          admin,
                                                          value,
                                                        ),
                                                itemBuilder:
                                                    (context) => [
                                                      const PopupMenuItem(
                                                        value: 'demote',
                                                        child: Text(
                                                          'Remove Admin',
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'remove',
                                                        child: Text(
                                                          'Remove from group',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .redAccent,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                      ],

                      // --- Invite Link Section (Admin/Owner only) ---
                      if (widget.isAdmin || widget.isOwner) ...[
                        Text(
                          'Invite Link',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              _isLoadingInvite
                                  ? const InviteLinkSectionSkeleton()
                                  : _inviteState == null
                                  ? _buildGenerateInviteRow()
                                  : _buildActiveInviteRow(_inviteState!),
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                      ],

                      // --- Danger Zone ---
                      if (isMember) ...[
                        GroupInfoActionButton(
                          icon: Icons.exit_to_app_rounded,
                          label: 'Leave Group',
                          color: Colors.orange,
                          onTap: () => _leaveGroup(context, liveGroup),
                        ),
                        const SizedBox(height: 12),
                      ],
                      GroupInfoActionButton(
                        icon: Icons.block_rounded,
                        label: 'Block Group',
                        color: Colors.red,
                        onTap: () => _blockGroup(context, liveGroup),
                      ),
                      if (widget.isOwner) ...[
                        const SizedBox(height: 12),
                        GroupInfoActionButton(
                          icon: Icons.delete_forever_rounded,
                          label: 'Delete Group',
                          color: Colors.red.shade900,
                          onTap: () => _deleteGroup(context, liveGroup),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InviteExpiryChoice {
  final Duration? duration; // null = never expires
  const _InviteExpiryChoice(this.duration);
}
