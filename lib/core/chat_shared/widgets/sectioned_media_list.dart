import 'package:flutter/material.dart';
import '../models/shared_media_item.dart';
import 'section_header.dart';
import 'shared_media_date_sectioner.dart';

class SectionedMediaList extends StatelessWidget {
  final List<SharedMediaItem> items;
  final Widget Function(BuildContext, SharedMediaItem) tileBuilder;

  const SectionedMediaList({
    super.key,
    required this.items,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final sections = SharedMediaDateSectioner.bucket(items);
    return CustomScrollView(
      slivers: [
        for (final section in sections) ...[
          SliverToBoxAdapter(child: SectionHeader(label: section.key)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => tileBuilder(context, section.value[index]),
              childCount: section.value.length,
            ),
          ),
        ],
      ],
    );
  }
}
