import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

class ChatBubbleShimmer extends StatelessWidget {
  final bool isMe;
  final int index;

  const ChatBubbleShimmer({super.key, required this.isMe, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    double widthMultiplier = (index % 2 == 0) ? 0.4 : 0.6;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _shimmerElement(35, 35, BoxShape.circle, baseColor, highlightColor),
            const Gap(8),
          ],
          _shimmerElement(
            50,
            MediaQuery.of(context).size.width * widthMultiplier,
            BoxShape.rectangle,
            baseColor,
            highlightColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 20),
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
