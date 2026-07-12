import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../widgets/about_us_feature_grid.dart';
import '../widgets/about_us_hero.dart';
import '../widgets/about_us_mission_card.dart';
import '../widgets/about_us_section_title.dart';
import '../widgets/about_us_social_links.dart';
import '../widgets/about_us_stats_row.dart';
import '../widgets/about_us_team_section.dart';
import '../widgets/about_us_version_footer.dart';

class AboutUsView extends StatefulWidget {
  const AboutUsView({super.key});

  @override
  State<AboutUsView> createState() => _AboutUsViewState();
}

class _AboutUsViewState extends State<AboutUsView>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late Animation<double> _heroScale;
  late Animation<double> _heroFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _heroScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));
    _heroFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeIn));
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _heroController.forward().then((_) => _contentController.forward());

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Hero sliver ──
          SliverToBoxAdapter(
            child: AboutUsHero(
              heroScale: _heroScale,
              heroFade: _heroFade,
              scrollOffset: _scrollOffset,
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AboutUsMissionCard(isDark: isDark, primary: primary),
                      const Gap(28),
                      AboutUsStatsRow(isDark: isDark, primary: primary),
                      const Gap(38),
                      AboutUsSectionTitle(
                        title: 'What We Offer',
                        isDark: isDark,
                      ),
                      const Gap(4),
                      AboutUsFeatureGrid(isDark: isDark, primary: primary),
                      const Gap(20),
                      AboutUsSectionTitle(
                        title: 'Built & Maintained By',
                        isDark: isDark,
                      ),
                      const Gap(14),
                      AboutUsTeamSection(isDark: isDark, primary: primary),
                      const Gap(28),
                      AboutUsSectionTitle(
                        title: 'Connect With Us',
                        isDark: isDark,
                      ),
                      const Gap(14),
                      AboutUsSocialLinks(isDark: isDark, primary: primary),
                      const Gap(28),
                      AboutUsVersionFooter(isDark: isDark, primary: primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
