import 'package:flutter/cupertino.dart';
import '../themes/app_colors.dart';

class CustomGreyContainer extends StatelessWidget {
  final String img;
  final double? width;
  final double? height;
  final double? radius;
  const CustomGreyContainer({
    super.key,
    required this.img,
    this.width,
    this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 40,
      height: height ?? 40,
      decoration: BoxDecoration(
        color: AppColors.gey2,
        borderRadius: BorderRadius.circular(radius ?? 16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(img, width: 12, height: 12),
      ),
    );
  }
}
