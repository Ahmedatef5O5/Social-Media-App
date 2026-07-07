import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../../core/secrets/app_secrets.dart';
import '../../../core/services/zego_token_service.dart';
import '../model/call_model.dart';
import '../cubits/single_call_cubit/call_cubit.dart';

class ZegoCallView extends StatefulWidget {
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
  State<ZegoCallView> createState() => _ZegoCallViewState();
}

class _ZegoCallViewState extends State<ZegoCallView> {
  String? _zegoToken;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadZegoToken();
  }

  Future<void> _loadZegoToken() async {
    try {
      final token = await ZegoTokenService.instance.generateToken(
        userId: widget.currentUserId,
      );
      if (mounted) setState(() => _zegoToken = token);
    } catch (e, st) {
      debugPrint('❌ ZegoCallView._loadZegoToken failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      await context.read<CallCubit>().endCall(widget.call.callId);

      if (!mounted) return;
      setState(() => _loadError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text('The call could not be initiated.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_zegoToken == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isVideo = widget.call.type == CallType.video;
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
        token: _zegoToken!,
        userID: widget.currentUserId,
        userName: widget.currentUserName,
        callID: widget.call.callId,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            debugPrint('🔴🔴🔴 ZEGO_CALL_END reason=${event.reason} 🔴🔴🔴');
            context.read<CallCubit>().endCall(widget.call.callId);
            defaultAction.call();
          },
        ),
        // events: ZegoUIKitPrebuiltCallEvents(
        //   onCallEnd: (event, defaultAction) {
        //     context.read<CallCubit>().endCall(widget.call.callId);
        //     defaultAction.call();
        //   },
        // ),
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
