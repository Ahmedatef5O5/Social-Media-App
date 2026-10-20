import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../settings/widgets/settings_detail_sliver_app_bar.dart';
import '../models/policy_section.dart';
import '../utils/markdown_section_parser.dart';
import '../widgets/accordion_tile.dart';
import '../widgets/support_contact_bar.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class TermsOfServiceView extends StatefulWidget {
  const TermsOfServiceView({super.key});

  @override
  State<TermsOfServiceView> createState() => _TermsOfServiceViewState();
}

class _TermsOfServiceViewState extends State<TermsOfServiceView> {
  late final Future<List<PolicySection>> _sections = _load();
  final Map<int, GlobalKey> _sectionKeys = {};

  Future<List<PolicySection>> _load() async {
    final raw = await rootBundle.loadString('assets/docs/terms_of_service.md');
    return MarkdownSectionParser.parse(raw);
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index]?.currentContext;
    if (ctx != null) {
      HapticFeedback.selectionClick();
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.10,
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
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                context.l10n.weCouldntLoadThis,
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final sections = snapshot.data!;
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
              SettingsDetailSliverAppBar(
                icon: Icons.gavel_rounded,
                title: context.l10n.settingsTermsOfService,
                subtitle: context.l10n.settingsTermsOfServiceSubtitle,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                context.l10n.tableOfContents,
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
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sections[i].title,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      for (var i = 0; i < sections.length; i++)
                        Padding(
                          key: _sectionKeys[i],
                          padding: const EdgeInsets.only(top: 20),
                          child: MarkdownBody(
                            data:
                                sections[i].title.isEmpty
                                    ? sections[i].body
                                    : '## ${sections[i].title}\n\n${sections[i].body}',
                            selectable: true,
                            styleSheet: styleSheet,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
