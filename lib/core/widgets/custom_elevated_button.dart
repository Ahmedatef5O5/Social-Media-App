import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  });
  final String txtBtn;
  final Widget? suffixIcon;
  final VoidCallback? onPressed;
  final Color? bgColor;
  final Color? txtColor;
  final Size? minimumSize, maximumSize;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: minimumSize ?? const Size(double.infinity, 55),
        maximumSize: maximumSize ?? const Size(double.infinity, 55),
        backgroundColor: bgColor ?? Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
      ),

      onPressed: onPressed,
      child:
          suffixIcon ??
          (isLoading
              ? CupertinoActivityIndicator(color: AppColors.black12)
              : Text(
                txtBtn,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: txtColor ?? AppColors.white,
                ),
              )),
    );
  }
}
