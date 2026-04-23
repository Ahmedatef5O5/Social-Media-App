import 'package:flutter/material.dart';

class MembersCountLabel extends StatelessWidget {
  final int count;
  final Color primary;

  const MembersCountLabel({
    super.key,
    required this.count,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Text('$count selected', style: TextStyle(color: primary));
  }
}
