import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import '../../../core/themes/app_colors.dart';

class EmptyPlaceholderState extends StatefulWidget {
  final String title, img;
  final Color? color;
  final TextStyle? style;
  final double opacity;
  final double? imgHeight, imgWidth;
  final int? periodSpeed;
  const EmptyPlaceholderState({
    super.key,
    required this.title,
    required this.img,
    this.color,
    this.style,
    this.opacity = 0.45,
    this.periodSpeed,
    this.imgHeight,
    this.imgWidth,
  });

  @override
  State<EmptyPlaceholderState> createState() => _EmptyPlaceholderStateState();
}

class _EmptyPlaceholderStateState extends State<EmptyPlaceholderState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: widget.opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              widget.img,
              controller: _controller,
              height: widget.imgHeight,
              width: widget.imgWidth,
              animate: true,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                _controller.repeat(
                  period: composition.duration ~/ (widget.periodSpeed ?? 2),
                );
              },
            ),
            const Gap(12),
            Text(
              widget.title,
              style:
                  widget.style ??
                  Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: widget.color ?? AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
