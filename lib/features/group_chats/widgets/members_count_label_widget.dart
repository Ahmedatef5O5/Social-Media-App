import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
    return Text(
      context.l10n.selected6(count),
      style: TextStyle(color: primary),
    );
  }
}
