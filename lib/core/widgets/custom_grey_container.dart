import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class CustomGreyContainer extends StatelessWidget {
  final String img;
  final double? width;
  final double? height;
  final double? radius;
  final void Function()? onTap;
  const CustomGreyContainer({
    super.key,
    required this.img,
    this.width,
    this.height,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width ?? 40,
        height: height ?? 40,
        decoration: BoxDecoration(
          color: AppColors.grey2,
          borderRadius: BorderRadius.circular(radius ?? 16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(img, width: 12, height: 12),
        ),
      ),
    );
  }
}
