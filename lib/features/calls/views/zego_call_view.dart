import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../../core/secrets/app_secrets.dart';
import '../model/call_model.dart';
import '../cubits/single_call_cubit/call_cubit.dart';

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
    final primaryColor = Theme.of(context).primaryColor;

    final darkerPrimary =
        HSLColor.fromColor(primaryColor)
            .withLightness(
              (HSLColor.fromColor(primaryColor).lightness - 0.15).clamp(
                0.0,
                1.0,
              ),
            )
            .toColor();

    ZegoUIKitPrebuiltCallConfig config =
        isVideo
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    config.audioVideoView.backgroundBuilder = (
      BuildContext context,
      Size size,
      ZegoUIKitUser? user,
      Map extraInfo,
    ) {
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, darkerPrimary],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.05,
            right: -30,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
                size: 200,
                color: Colors.white,
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.08,
            left: -50,
            child: Opacity(
              opacity: 0.07,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 22),
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.35,
            left: 16,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(
                Icons.graphic_eq_rounded,
                size: 90,
                color: Colors.white,
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.06,
            left: 20,
            child: Opacity(opacity: 0.09, child: _buildDotGrid()),
          ),

          Positioned(
            bottom: size.height * 0.25,
            right: 20,
            child: Opacity(
              opacity: 0.07,
              child: const Icon(
                Icons.mic_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    };

    if (isVideo) {
      config.audioVideoView.backgroundBuilder = (
        BuildContext context,
        Size size,
        ZegoUIKitUser? user,
        Map extraInfo,
      ) {
        return const SizedBox.shrink();
      };
    }

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: AppSecrets.zegoAppId,
        appSign: AppSecrets.zegoAppSign,
        userID: currentUserId,
        userName: currentUserName,
        callID: call.callId,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            context.read<CallCubit>().endCall(call.callId);
            defaultAction.call();
          },
        ),
      ),
    );
  }

  Widget _buildDotGrid() {
    return SizedBox(
      width: 60,
      height: 60,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 16,
        itemBuilder:
            (_, __) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
      ),
    );
  }
}
