import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_action_button.dart';
import 'profile_ui_tokens.dart';

class ProfileAnimatedActionButton extends StatefulWidget {
  final bool isActive;
  final String idleLabel;
  final String activeLabel;
  final IconData idleIcon;
  final IconData activeIcon;
  final ProfileActionStyle idleStyle;
  final ProfileActionStyle activeStyle;
  final Future<bool> Function() onPressed;
  final double? width;

  const ProfileAnimatedActionButton({
    super.key,
    required this.isActive,
    required this.idleLabel,
    required this.activeLabel,
    required this.idleIcon,
    required this.activeIcon,
    required this.idleStyle,
    required this.activeStyle,
    required this.onPressed,
    this.width,
  });

  @override
  State<ProfileAnimatedActionButton> createState() =>
      _ProfileAnimatedActionButtonState();
}

enum _Visual { idle, loading, success, active }

class _ProfileAnimatedActionButtonState
    extends State<ProfileAnimatedActionButton> {
  static const _successGreen = Color(0xFF34C759);
  static const double _height = ProfileUiTokens.buttonHeight;

  late _Visual _visual = widget.isActive ? _Visual.active : _Visual.idle;
  bool _isBusy = false;

  _Visual get _restingVisual => widget.isActive ? _Visual.active : _Visual.idle;

  @override
  void didUpdateWidget(covariant ProfileAnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // While an animation is running the tap handler owns the visual state.
    if (!_isBusy && oldWidget.isActive != widget.isActive) {
      setState(() => _visual = _restingVisual);
    }
  }

  Future<void> _handleTap() async {
    if (_isBusy) return;
    final wasActive = widget.isActive;

    HapticFeedback.lightImpact();
    setState(() {
      _isBusy = true;
      _visual = _Visual.loading;
    });

    bool succeeded = false;
    try {
      succeeded = await widget.onPressed();
    } catch (_) {
      succeeded = false;
    }
    if (!mounted) return;

    if (succeeded && !wasActive) {
      HapticFeedback.mediumImpact();
      setState(() => _visual = _Visual.success);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
    }

    setState(() {
      _visual = _restingVisual;
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);
    final idleColors = profileActionColors(widget.idleStyle, tokens);
    final activeColors = profileActionColors(widget.activeStyle, tokens);
    final isMorphed = _visual == _Visual.loading || _visual == _Visual.success;

    final Color background = switch (_visual) {
      _Visual.idle => idleColors.background,
      _Visual.loading => tokens.primary,
      _Visual.success => _successGreen,
      _Visual.active => activeColors.background,
    };
    final Color borderColor = switch (_visual) {
      _Visual.idle => idleColors.border,
      _Visual.active => activeColors.border,
      _ => Colors.transparent,
    };

    return SizedBox(
      height: _height,
      width: widget.width ?? double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
          final targetWidth = isMorphed ? _height : fullWidth;

          return Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isBusy ? null : _handleTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: targetWidth,
                height: _height,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(
                    isMorphed ? _height / 2 : ProfileUiTokens.buttonRadius,
                  ),
                  border: Border.all(color: borderColor, width: 1),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) {
                    final curved = CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutBack,
                    );
                    return FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: curved, child: child),
                    );
                  },
                  child: _buildContent(idleColors, activeColors),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    ({Color background, Color foreground, Color border}) idleColors,
    ({Color background, Color foreground, Color border}) activeColors,
  ) {
    switch (_visual) {
      case _Visual.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        );
      case _Visual.success:
        return const Icon(
          Icons.check_rounded,
          key: ValueKey('success'),
          color: Colors.white,
          size: 20,
        );
      case _Visual.idle:
        return _label(
          key: const ValueKey('idle'),
          icon: widget.idleIcon,
          text: widget.idleLabel,
          color: idleColors.foreground,
        );
      case _Visual.active:
        return _label(
          key: const ValueKey('active'),
          icon: widget.activeIcon,
          text: widget.activeLabel,
          color: activeColors.foreground,
        );
    }
  }

  Widget _label({
    required Key key,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
