import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';

import '../themes/app_colors.dart';

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
    this.maximumSize,
    this.side,
    this.elevation,
    this.shape,
    this.txtBtnStyle,
  });
  final String txtBtn;
  final Widget? suffixIcon;
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
        minimumSize: minimumSize ?? const Size(double.infinity, 55),
        maximumSize: maximumSize ?? const Size(double.infinity, 55),
        backgroundColor: bgColor ?? Theme.of(context).primaryColor,
        shape:
            shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: side,
        elevation: elevation,
      ),

      onPressed: onPressed,
      child:
          suffixIcon ??
          (isLoading
              ? const CustomLoadingIndicator()
              : Text(
                txtBtn,
                style:
                    txtBtnStyle ??
                    Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: txtColor ?? AppColors.white,
                    ),
              )),
    );
  }
}
