import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/deep_link/services/deep_link_service.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../core/toast/app_toast.dart';
import '../helpers/invite_link_section_skeleton.dart';
import '../models/group_invite_state.dart';
import '../services/group_chat_services.dart';
import 'group_confirm_dialog.dart';

/// The whole "Invite Link" card — loading, generate, active-link display
/// (copy/forward/revoke), and its expiry badge — as a fully
/// self-contained widget. Extracted out of `_GroupSettingsViewState`
/// (V4-04): this used to own 4 state fields, a `Timer`, and 10 methods
/// inside the parent view even though nothing else on that screen reads
/// or depends on invite state.
class GroupInviteLinkSection extends StatefulWidget {
  final String groupId;
  final String groupName;
  final GroupChatServices services;

  const GroupInviteLinkSection({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.services,
  });

  @override
  State<GroupInviteLinkSection> createState() => _GroupInviteLinkSectionState();
}

class _GroupInviteLinkSectionState extends State<GroupInviteLinkSection> {
  GroupInviteState? _inviteState;
  bool _isLoadingInvite = true;
  bool _isUpdatingInvite = false;
  Timer? _inviteBadgeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.services.hasCachedInviteState(widget.groupId)) {
      _inviteState = widget.services.getCachedInviteState(widget.groupId);
      _isLoadingInvite = false;
      _refreshInviteStateSilently();
    } else {
      _loadInviteState();
    }
  }

  @override
  void dispose() {
    _inviteBadgeTimer?.cancel();
    super.dispose();
  }

  String _inviteUrlFor(String hash) => DeepLinkService.urlForGroupInvite(hash);

  Future<void> _refreshInviteStateSilently() async {
    try {
      final state = await widget.services.getGroupInviteState(widget.groupId);
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
      final state = await widget.services.getGroupInviteState(widget.groupId);
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
      final state = await widget.services.generateGroupInviteLink(
        widget.groupId,
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
    final confirm = await GroupConfirmDialog.show(
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
      await widget.services.revokeGroupInviteLink(widget.groupId);
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
            'Join "${widget.groupName}" on Social Media App: ${_inviteUrlFor(hash)}',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite Link',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      ],
    );
  }
}

class _InviteExpiryChoice {
  final Duration? duration; // null = never expires
  const _InviteExpiryChoice(this.duration);
}
