import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/custom_header_widget.dart';

class DiscoverPeopleHeaderSection extends StatelessWidget {
  const DiscoverPeopleHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      title: 'Discover People',
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      actions: Icon(
        Icons.more_vert_outlined,
        color: Theme.of(context).primaryColor,
        size: 26,
      ),
    );
  }
}
