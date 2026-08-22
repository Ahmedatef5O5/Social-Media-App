import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../helpers/ai_chat_colors.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius:
              shape == BoxShape.rectangle
                  ? BorderRadius.circular(borderRadius)
                  : null,
        ),
      ),
    );
  }
}

class AiMessageBubbleShimmer extends StatelessWidget {
  const AiMessageBubbleShimmer({
    super.key,
    required this.isUser,
    required this.lineWidthFractions,
  });

  final bool isUser;

  final List<double> lineWidthFractions;

  BorderRadius get _radius => BorderRadius.only(
    topLeft: const Radius.circular(20),
    topRight: const Radius.circular(20),
    bottomLeft: Radius.circular(isUser ? 20 : 4),
    bottomRight: Radius.circular(isUser ? 4 : 20),
  );

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.74;
    final (base, highlight) = AiChatColors.shimmerTones(
      Theme.of(context).primaryColor,
    );

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(color: highlight.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < lineWidthFractions.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            ShimmerBox(
              width: maxBubbleWidth * lineWidthFractions[i],
              height: 12,
              baseColor: base,
              highlightColor: highlight,
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            ShimmerBox(
              width: 26,
              height: 26,
              baseColor: base,
              highlightColor: highlight,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class AiChatMessagesShimmerList extends StatelessWidget {
  const AiChatMessagesShimmerList({super.key});
  List<double> _shapeFor(int index) {
    final random = Random(index);
    final lineCount = switch (random.nextDouble()) {
      < 0.5 => 1,
      < 0.85 => 2,
      _ => 3,
    };
    return List.generate(lineCount, (_) => 0.35 + random.nextDouble() * 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const approxRowHeight = 62.0;
        final itemCount = (constraints.maxHeight / approxRowHeight)
            .ceil()
            .clamp(6, 24);

        return ListView.builder(
          reverse: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final isUser = index.isEven;
            return AiMessageBubbleShimmer(
              isUser: isUser,
              lineWidthFractions: _shapeFor(index),
            );
          },
        );
      },
    );
  }
}
