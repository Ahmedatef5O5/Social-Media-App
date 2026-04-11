import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.txtBtn,
    required this.onPressed,
    this.bgColor,
    this.txtColor,
    this.isLoading = false,
    this.minimumSize,
    this.suffixIcon,
    this.prefixIcon,
    this.maximumSize,
    this.side,
    this.elevation,
    this.shape,
    this.txtBtnStyle,
  });
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: minimumSize ?? const Size(double.infinity, 55),
        maximumSize: maximumSize ?? const Size(double.infinity, 55),
        backgroundColor: bgColor ?? Theme.of(context).primaryColor,
        shape:
            shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: side,
        elevation: elevation,
      ),

      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? const CustomLoadingIndicator()
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[prefixIcon!, const Gap(10)],
                  Text(
                    txtBtn,
                    style:
                        txtBtnStyle ??
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: txtColor ?? Colors.white,
                        ),
                  ),
                  if (suffixIcon != null) ...[const Gap(10), suffixIcon!],
                ],
              ),
    );
  }
}
