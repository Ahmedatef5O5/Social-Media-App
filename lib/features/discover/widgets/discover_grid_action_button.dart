import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact full-width action button used inside [DiscoverPersonGridCardWidget].
///
/// Mirrors the exact interaction model of `AnimatedActionButton`
/// (idle -> loading -> success -> active, with haptics) but restyles the
/// "active" state as an OUTLINED primary pill instead of a filled grey pill,
/// per the new Discover grid mockup.

class DiscoverGridActionButton extends StatefulWidget {
  final bool isActive;
  final String idleLabel;
  final String activeLabel;
  final IconData idleIcon;
  final IconData activeIcon;
  final Future<void> Function() onPressed;
  final double height;

  const DiscoverGridActionButton({
    super.key,
    required this.isActive,
    required this.idleLabel,
    required this.activeLabel,
    required this.idleIcon,
    required this.activeIcon,
    required this.onPressed,
    this.height = 36,
  });

  @override
  State<DiscoverGridActionButton> createState() =>
      _DiscoverGridActionButtonState();
}

enum _ButtonVisual { idle, loading, success, active }

class _DiscoverGridActionButtonState extends State<DiscoverGridActionButton> {
  late _ButtonVisual _visual =
      widget.isActive ? _ButtonVisual.active : _ButtonVisual.idle;
  bool _isBusy = false;

  static const _successGreen = Color(0xFF34C759);

  @override
  void didUpdateWidget(covariant DiscoverGridActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isBusy && oldWidget.isActive != widget.isActive) {
      setState(() {
        _visual = widget.isActive ? _ButtonVisual.active : _ButtonVisual.idle;
      });
    }
  }

  Future<void> _handleTap() async {
    if (_isBusy) return;
    final wasActive = widget.isActive;

    HapticFeedback.lightImpact();
    setState(() {
      _isBusy = true;
      _visual = _ButtonVisual.loading;
    });

    try {
      await widget.onPressed();
      if (!mounted) return;

      if (!wasActive) {
        HapticFeedback.mediumImpact();
        setState(() => _visual = _ButtonVisual.success);
        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted) return;
        setState(() => _visual = _ButtonVisual.active);
      } else {
        setState(() => _visual = _ButtonVisual.idle);
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _visual = wasActive ? _ButtonVisual.active : _ButtonVisual.idle,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMorphed =
        _visual == _ButtonVisual.loading || _visual == _ButtonVisual.success;
    final isOutlined = _visual == _ButtonVisual.active;

    final Color bgColor = switch (_visual) {
      _ButtonVisual.idle => theme.primaryColor,
      _ButtonVisual.loading => theme.primaryColor,
      _ButtonVisual.success => _successGreen,
      _ButtonVisual.active => Colors.transparent,
    };

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
          final targetWidth = isMorphed ? widget.height : fullWidth;

          return Center(
            child: GestureDetector(
              onTap: _isBusy ? null : _handleTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: targetWidth,
                height: widget.height,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      isOutlined
                          ? Border.all(color: theme.primaryColor, width: 1.4)
                          : null,
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
                  child: _buildContent(theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_visual) {
      case _ButtonVisual.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );

      case _ButtonVisual.success:
        return const Icon(
          Icons.check_rounded,
          key: ValueKey('success'),
          color: Colors.white,
          size: 17,
        );

      case _ButtonVisual.idle:
        return Padding(
          key: const ValueKey('idle'),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.idleIcon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.idleLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );

      case _ButtonVisual.active:
        return Padding(
          key: const ValueKey('active'),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.activeIcon, size: 14, color: theme.primaryColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.activeLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
