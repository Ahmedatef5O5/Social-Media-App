import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../group_calls/models/group_call_model.dart';

class GroupCallStatusTile extends StatefulWidget {
  const GroupCallStatusTile({super.key, required this.callId});

  final String callId;

  @override
  State<GroupCallStatusTile> createState() => _GroupCallStatusTileState();
}

class _GroupCallStatusTileState extends State<GroupCallStatusTile> {
  GroupCallModel? _call;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GroupCallStatusTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.callId != widget.callId) {
      _loadToken++;
      _sub?.cancel();
      _sub = null;
      _call = null;
      _load();
    }
  }

  @override
  void dispose() {
    _loadToken++;
    _sub?.cancel();
    super.dispose();
  }

  static bool _isLive(GroupCallStatus status) =>
      status == GroupCallStatus.ringing ||
      status == GroupCallStatus.accepted ||
      status == GroupCallStatus.ongoing;

  Future<void> _load() async {
    final callId = widget.callId;
    if (callId.isEmpty) return;
    final token = ++_loadToken;

    try {
      final row =
          await SupabaseProvider.client
              .from('group_calls')
              .select()
              .eq('call_id', callId)
              .maybeSingle();
      if (!mounted || token != _loadToken || row == null) return;

      final call = GroupCallModel.fromMap(row);
      setState(() => _call = call);
      if (_isLive(call.status)) _watch(callId, token);
    } catch (e) {
      debugPrint('[GroupCallStatusTile] load error: $e');
    }
  }

  void _watch(String callId, int token) {
    _sub?.cancel();
    _sub = SupabaseProvider.client
        .from('group_calls')
        .stream(primaryKey: ['call_id'])
        .eq('call_id', callId)
        .listen(
          (rows) {
            if (!mounted || token != _loadToken || rows.isEmpty) return;
            final call = GroupCallModel.fromMap(rows.first);
            setState(() => _call = call);
            if (!_isLive(call.status)) {
              _sub?.cancel();
              _sub = null;
            }
          },
          onError: (Object e) {
            debugPrint('[GroupCallStatusTile] stream error: $e');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    if (call == null) return const SizedBox.shrink();

    final isMissed = call.status == GroupCallStatus.missed;
    final isRinging = call.status == GroupCallStatus.ringing;
    final isOngoing =
        call.status == GroupCallStatus.accepted ||
        call.status == GroupCallStatus.ongoing;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isMissed
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            call.type == GroupCallType.video ? Icons.videocam : Icons.phone,
            color: isMissed ? Colors.red : Colors.green,
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                call.type == GroupCallType.video
                    ? 'Group Video Call'
                    : 'Group Voice Call',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                isMissed
                    ? 'Missed Call'
                    : isRinging
                    ? 'Ringing...'
                    : isOngoing
                    ? 'Ongoing • Tap to Join'
                    : (call.duration != null && call.duration!.isNotEmpty)
                    ? 'Ended • ${call.duration}'
                    : 'Ended',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
