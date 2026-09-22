import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_ui_tokens.dart';

enum ProfileActionStyle {
  /// Filled primary — "Add Friend", "Accept".
  primary,

  /// Soft primary container — "Friends".
  tonal,

  /// Neutral filled — "Following".
  neutral,

  /// Surface + outline + primary label — "Edit Profile".
  outlinePrimary,

  /// Transparent + outline + muted label — "Requested".
  outlineMuted,

  /// Transparent + primary outline + primary label — "Follow".
  outlineAccent,
}

({Color background, Color foreground, Color border}) profileActionColors(
  ProfileActionStyle style,
  ProfileUiTokens t,
) {
  switch (style) {
    case ProfileActionStyle.primary:
      return (
        background: t.primary,
        foreground: t.onPrimary,
        border: Colors.transparent,
      );
    case ProfileActionStyle.tonal:
      return (
        background: t.primaryTonal,
        foreground: t.iconAccent,
        border: Colors.transparent,
      );
    case ProfileActionStyle.neutral:
      return (
        background: t.surfaceVariant,
        foreground: t.onSurface,
        border: Colors.transparent,
      );
    case ProfileActionStyle.outlinePrimary:
      return (
        background: t.surface,
        foreground: t.iconAccent,
        border: t.outline,
      );
    case ProfileActionStyle.outlineMuted:
      return (
        background: Colors.transparent,
        foreground: t.onSurfaceVariant,
        border: t.outline,
      );
    case ProfileActionStyle.outlineAccent:
      return (
        background: Colors.transparent,
        foreground: t.iconAccent,
        border: t.primary,
      );
  }
}

class ProfileActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ProfileActionStyle style;
  final bool expand;

  const ProfileActionButton({
    super.key,
    required this.label,
    required this.style,
    this.icon,
    this.onPressed,
    this.expand = true,
  });

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);
    final colors = profileActionColors(widget.style, tokens);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ProfileUiTokens.buttonRadius),
      side:
          colors.border == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: colors.border, width: 1),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 16, color: colors.foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: colors.background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap:
              widget.onPressed == null
                  ? null
                  : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  },
          child: SizedBox(
            height: ProfileUiTokens.buttonHeight,
            width: widget.expand ? double.infinity : null,
            child: Center(
              widthFactor: widget.expand ? null : 1,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSquareIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? iconColor;

  const ProfileSquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor,
  });

  @override
  State<ProfileSquareIconButton> createState() =>
      _ProfileSquareIconButtonState();
}

class _ProfileSquareIconButtonState extends State<ProfileSquareIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ProfileUiTokens.buttonRadius),
      side: BorderSide(color: tokens.outline, width: 1),
    );

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: Material(
          color: tokens.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: shape,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onPressed();
            },
            child: SizedBox(
              width: ProfileUiTokens.buttonHeight,
              height: ProfileUiTokens.buttonHeight,
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.iconColor ?? tokens.iconAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
