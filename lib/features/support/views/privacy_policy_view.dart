import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../settings/widgets/settings_detail_sliver_app_bar.dart';
import '../models/policy_section.dart';
import '../utils/markdown_section_parser.dart';
import '../widgets/accordion_tile.dart';
import '../widgets/support_contact_bar.dart';

class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  late final Future<List<PolicySection>> _sections = _load();
  final Map<int, GlobalKey> _sectionKeys = {};

  Future<List<PolicySection>> _load() async {
    final raw = await rootBundle.loadString('assets/docs/privacy_policy.md');
    return MarkdownSectionParser.parse(raw);
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const SupportContactBar(),
      body: FutureBuilder<List<PolicySection>>(
        future: _sections,
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

          final sections = snapshot.data!;
          // Sections with an empty title are the leading, un-headed intro
          // block ("last updated" + opening paragraph) and don't get a TOC
          // entry or a jump-to key.
          final tocEntries = <int>[];
          for (var i = 0; i < sections.length; i++) {
            if (sections[i].title.isNotEmpty) {
              _sectionKeys.putIfAbsent(i, () => GlobalKey());
              tocEntries.add(i);
            }
          }

          final styleSheet = MarkdownStyleSheet(
            p: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            h1: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            h2: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            strong: const TextStyle(fontWeight: FontWeight.w700),
            listBullet: theme.textTheme.bodyMedium,
            blockSpacing: 14,
          );

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SettingsDetailSliverAppBar(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                sliver: SliverList.list(
                  children: [
                    if (tocEntries.isNotEmpty)
                      AccordionTile(
                        initiallyExpanded: true,
                        title: Row(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Table of Contents',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final i in tocEntries)
                              InkWell(
                                onTap: () => _scrollToSection(i),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    sections[i].title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    for (var i = 0; i < sections.length; i++)
                      Padding(
                        key: _sectionKeys[i],
                        padding: const EdgeInsets.only(top: 18),
                        child: MarkdownBody(
                          data: sections[i].body,
                          selectable: true,
                          styleSheet: styleSheet,
                        ),
                      ),
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
