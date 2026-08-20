import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MutedBadgeIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const MutedBadgeIcon({super.key, this.size = 10, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: FaIcon(
        FontAwesomeIcons.bellSlash,
        size: size,
        color: color ?? Colors.grey.shade500,
      ),
    );
  }
}
