import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/presence_cubit/presence_cubit.dart';

class PresenceAvatarWidget extends StatelessWidget {
  const PresenceAvatarWidget({
    super.key,
    required this.userId,
    required this.child,
    this.avatarSize = 36,
    this.showDot = true,
    this.showBorder = true,
  });

  final String userId;
  final Widget child;
  final double avatarSize;
  final bool showDot;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    if (!showDot && !showBorder) return child;

    final isOnline = context.select<PresenceCubit, bool>(
      (cubit) => cubit.isOnline(userId),
    );

    if (!isOnline) return child;

    final dotSize = (avatarSize * 0.20).clamp(9.0, 16.0);
    final borderWidth = (avatarSize * 0.03).clamp(1.2, 3.2);
    final double offset = (avatarSize * 0.1464) - (dotSize / 2);

    Widget avatarWithBorder = SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              showBorder
                  ? Border.all(color: Colors.green, width: borderWidth)
                  : null,
        ),
        child: ClipOval(child: child),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWithBorder,
        if (showDot)
          Positioned(
            bottom: offset,
            right: offset,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
