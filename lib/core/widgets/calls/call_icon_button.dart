import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import '../../../features/single_calls/model/call_model.dart';
import '../../../features/single_calls/services/call_signaling_service.dart';
import '../../../features/single_chats/helper/call_actions.dart';
import '../../services/active_call/active_call_session_data.dart';
import '../../services/active_call/cubit/active_call_session_cubit.dart';
import '../../toast/app_toast.dart';

class CallIconButton extends StatelessWidget {
  final CallType type;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final EdgeInsetsGeometry? padding;
  final double? size;
  final Color? color;
  final ButtonStyle? style;

  const CallIconButton({
    super.key,
    required this.type,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    this.color,
    this.size,
    this.padding,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveCallSessionCubit, ActiveCallSessionData?>(
      builder: (context, activeSession) {
        final isLocalUserBusy = activeSession != null;
        return IconButton(
          constraints: const BoxConstraints(),
          style: style,
          padding: padding ?? EdgeInsets.zero,
          tooltip: type == CallType.video ? 'Video call' : 'Voice call',
          icon: Icon(
            size: size ?? 25,
            type == CallType.video
                ? Icons.videocam_outlined
                : Icons.call_outlined,
            color:
                isLocalUserBusy
                    ? Colors.grey
                    : Theme.of(context).primaryColor.withValues(alpha: 0.85),
          ),
          onPressed: isLocalUserBusy ? null : () => _startCall(context),
        );
      },
    );
  }

  Future<void> _startCall(BuildContext context) async {
    final signaling = context.read<CallSignalingService>();
    final receiverBusy = await signaling.isUserBusy(receiverId);
    if (!context.mounted) return;

    if (receiverBusy) {
      AppToast.info('$receiverName is busy on another call');
      return;
    }

    final call = await CallActions.buildCall(
      type: type,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
    );
    if (call == null || !context.mounted) return;
    context.read<CallCubit>().makeAudioCall(call);
  }
}
