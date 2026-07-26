import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../../../core/secrets/app_secrets.dart';
import '../../../core/services/active_call/cubit/active_call_session_cubit.dart';
import '../../../core/services/active_call/call_termination_service.dart';
import '../../../core/services/notification_services.dart';
import '../../../core/services/zego_token_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
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
  bool _isEnding = false;
  @override
  void initState() {
    super.initState();
    _loadZegoToken();

    final isCaller = widget.currentUserId == widget.call.callerId;
    final otherPersonName =
        isCaller ? widget.call.receiverName : widget.call.callerName;
    final otherPersonAvatar =
        isCaller ? widget.call.receiverAvatar : widget.call.callerAvatar;

    context.read<ActiveCallSessionCubit>().startSingleCallSession(
      callId: widget.call.callId,
      title: otherPersonName,
      avatarUrl: otherPersonAvatar,
      isVideo: widget.call.type == CallType.video,
      startedAt: widget.call.startTime ?? DateTime.now(),
    );
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

      if (mounted) {
        context.read<ActiveCallSessionCubit>().endSession();
        setState(() => _loadError = e.toString());
      }
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
      return const Scaffold(body: Center(child: CustomLoadingIndicator()));
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

    // Minimize button — identical setup to ZegoGroupCallView's, so behavior
    // and visuals match exactly between single and group calls. This is
    // what was entirely missing for 1:1 calls before.
    config.topMenuBar
      ..isVisible = true
      ..buttons = []
      ..extendButtons = [_buildMinimizeButton(context)]
      ..backgroundColor = Colors.black.withValues(alpha: 0.25)
      ..padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
      ..margin = const EdgeInsets.only(top: 8, left: 8, right: 8);

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

    config.avatarBuilder = (
      BuildContext context,
      Size size,
      ZegoUIKitUser? user,
      Map extraInfo,
    ) {
      if (user == null) return const SizedBox.shrink();

      final double diameter =
          size.width < size.height ? size.width : size.height;

      return SizedBox(
        width: diameter,
        height: diameter,
        child: FutureBuilder(
          future:
              SupabaseProvider.client
                  .from('users')
                  .select('image_url')
                  .eq('id', user.id)
                  .maybeSingle(),
          builder: (context, snapshot) {
            final imageUrl = snapshot.data?['image_url'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              return ClipOval(
                child: CachedCloudinaryImage(
                  secureUrl: imageUrl,
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  isAvatar: true,
                  placeholder:
                      (context) => Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                  errorWidget:
                      (context, error) => _buildDefaultAvatar(
                        user.name,
                        primaryColor,
                        diameter,
                      ),
                ),
              );
            }
            return _buildDefaultAvatar(user.name, primaryColor, diameter);
          },
        ),
      );
    };

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: AppSecrets.zegoAppId,
        token: _zegoToken!,
        userID: widget.currentUserId,
        userName: widget.currentUserName,
        callID: widget.call.callId,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) async {
            debugPrint('🔴🔴🔴 ZEGO_CALL_END reason=${event.reason} 🔴🔴🔴');

            if (_isEnding) {
              defaultAction.call();
              return;
            }
            _isEnding = true;

            await CallTerminationService.endActiveCall(
              signalEnd:
                  () => context.read<CallCubit>().endCall(widget.call.callId),
            );

            context.read<ActiveCallSessionCubit>().endSession();
            defaultAction.call();

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMinimizeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleMinimize(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(
          Icons.close_fullscreen_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  void _handleMinimize(BuildContext context) {
    final navContext = navigatorKey.currentState?.context ?? context;
    ZegoUIKitPrebuiltCallController().minimize.minimize(navContext);
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
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

  Widget _buildDefaultAvatar(String name, Color primary, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: diameter * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
