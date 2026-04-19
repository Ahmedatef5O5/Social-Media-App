import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/secrets/app_secrets.dart';
import '../model/call_model.dart';
import '../cubit/call_cubit.dart';

class ZegoCallView extends StatelessWidget {
  final CallModel call;
  final String currentUserId;
  final String currentUserName;

  const ZegoCallView({
    super.key,
    required this.call,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = call.type == CallType.video;

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: AppSecrets.zegoAppId,
        appSign: AppSecrets.zegoAppSign,
        userID: currentUserId,
        userName: currentUserName,
        callID: call.callId,

        config:
            isVideo
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),

        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            context.read<CallCubit>().endCall(call.callId);

            defaultAction.call();
          },
        ),
      ),
    );
  }
}
