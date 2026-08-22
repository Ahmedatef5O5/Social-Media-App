import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

class ChatBubbleShimmer extends StatelessWidget {
  final bool isMe;
  final bool showAvatar;
  final double widthMultiplier;
  final bool isDateSeparator;

  const ChatBubbleShimmer({
    super.key,
    required this.isMe,
    this.showAvatar = false,
    this.widthMultiplier = 0.5,
    this.isDateSeparator = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    if (isDateSeparator) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: _shimmerElement(
            24,
            110,
            BoxShape.rectangle,
            baseColor,
            highlightColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar || isMe ? 12 : 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              _shimmerElement(
                35,
                35,
                BoxShape.circle,
                baseColor,
                highlightColor,
              )
            else
              const SizedBox(width: 35),
            const Gap(8),
          ],
          _shimmerElement(
            45,
            MediaQuery.of(context).size.width * widthMultiplier,
            BoxShape.rectangle,
            baseColor,
            highlightColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : (showAvatar ? 4 : 20)),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerElement(
    double height,
    double width,
    BoxShape shape,
    Color base,
    Color highlight, {
    BorderRadius? borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
