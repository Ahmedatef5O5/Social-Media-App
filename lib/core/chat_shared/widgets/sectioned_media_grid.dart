import 'package:flutter/material.dart';
import '../models/shared_media_item.dart';
import 'section_header.dart';
import 'shared_media_date_sectioner.dart';

class SectionedMediaGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final Widget Function(BuildContext, SharedMediaItem) tileBuilder;

  const SectionedMediaGrid({
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => tileBuilder(context, section.value[index]),
                childCount: section.value.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
