import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

class CustomElevatedButton extends StatefulWidget {
  final String txtBtn;
  final Widget? suffixIcon, prefixIcon;
  final VoidCallback? onPressed;
  final Color? bgColor;
  final Color? txtColor;
  final Size? minimumSize, maximumSize;
  final OutlinedBorder? shape;
  final BorderSide? side;
  final double? elevation;
  final TextStyle? txtBtnStyle;
  final bool isLoading;
  final bool isSuccess;

  const CustomElevatedButton({
    super.key,
    required this.txtBtn,
    required this.onPressed,
    this.bgColor,
    this.txtColor,
    this.isLoading = false,
    this.isSuccess = false,
    this.minimumSize,
    this.suffixIcon,
    this.prefixIcon,
    this.maximumSize,
    this.side,
    this.elevation,
    this.shape,
    this.txtBtnStyle,
  });

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  static const Color _successGreen = Color(0xFF34C759);

  @override
  void didUpdateWidget(covariant CustomElevatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSuccess && widget.isSuccess) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = widget.isLoading || widget.isSuccess;
    final Color baseBgColor = widget.bgColor ?? Theme.of(context).primaryColor;
    final Color effectiveBgColor =
        widget.isSuccess ? _successGreen : baseBgColor;
    final Color effectiveFgColor = widget.txtColor ?? Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: widget.minimumSize ?? const Size(double.infinity, 55),
        maximumSize: widget.maximumSize ?? const Size(double.infinity, 55),
        backgroundColor: effectiveBgColor,
        disabledBackgroundColor: isBusy ? effectiveBgColor : null,
        disabledForegroundColor: isBusy ? effectiveFgColor : null,
        shape:
            widget.shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: widget.side,
        elevation: widget.elevation,
      ),
      onPressed:
          isBusy
              ? null
              : (widget.onPressed == null
                  ? null
                  : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        transitionBuilder: (child, anim) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: curved, child: child),
          );
        },
        child: _buildChild(context, effectiveFgColor),
      ),
    );
  }

  Widget _buildChild(BuildContext context, Color foregroundColor) {
    if (widget.isSuccess) {
      return const Icon(
        Icons.check_rounded,
        key: ValueKey('success'),
        color: Colors.white,
        size: 26,
      );
    }

    if (widget.isLoading) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
    }

    return Row(
      key: const ValueKey('content'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[widget.prefixIcon!, const Gap(10)],
        Text(
          widget.txtBtn,
          style:
              widget.txtBtnStyle ??
              Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(color: foregroundColor),
        ),
        if (widget.suffixIcon != null) ...[const Gap(10), widget.suffixIcon!],
      ],
    );
  }
}
