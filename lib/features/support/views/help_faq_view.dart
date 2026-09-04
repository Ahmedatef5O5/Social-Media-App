import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../settings/widgets/settings_detail_sliver_app_bar.dart';
import '../models/faq_category.dart';
import '../widgets/accordion_tile.dart';
import '../widgets/support_contact_bar.dart';

class HelpFaqView extends StatefulWidget {
  const HelpFaqView({super.key});

  @override
  State<HelpFaqView> createState() => _HelpFaqViewState();
}

class _HelpFaqViewState extends State<HelpFaqView> {
  late final Future<List<FaqCategory>> _categories = _load();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Future<List<FaqCategory>> _load() async {
    final raw = await rootBundle.loadString('assets/docs/help_faq.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => FaqCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, FaqItem>> _searchResults(List<FaqCategory> categories) {
    final q = _query.trim().toLowerCase();
    final results = <MapEntry<String, FaqItem>>[];
    for (final category in categories) {
      for (final item in category.items) {
        if (item.question.toLowerCase().contains(q) ||
            item.answer.toLowerCase().contains(q)) {
          results.add(MapEntry(category.title, item));
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const SupportContactBar(),
      body: FutureBuilder<List<FaqCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                "We couldn't load this content. Please try again later.",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final categories = snapshot.data!;
          final isSearching = _query.trim().isNotEmpty;
          final results =
              isSearching
                  ? _searchResults(categories)
                  : const <MapEntry<String, FaqItem>>[];

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SettingsDetailSliverAppBar(
                icon: Icons.help_outline_rounded,
                title: 'Help & FAQ',
                subtitle: 'Get answers to common questions',
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchHeaderDelegate(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search for a question…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon:
                            isSearching
                                ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor:
                            theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.shade100,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isSearching)
                results.isEmpty
                    ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'No results for "$_query"',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                    : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      sliver: SliverList.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final entry = results[index];
                          return AccordionTile(
                            initiallyExpanded: results.length == 1,
                            title: Text(
                              entry.value.question,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(
                              entry.value.answer,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                              ),
                            ),
                          );
                        },
                      ),
                    )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  sliver: SliverList.list(
                    children: [
                      for (final category in categories) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                category.icon,
                                size: 18,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final item in category.items)
                          AccordionTile(
                            title: Text(
                              item.question,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(
                              item.answer,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _SearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return true;
  }
}
