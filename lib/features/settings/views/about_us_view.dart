import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_routes.dart';

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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Hero sliver ──
          SliverToBoxAdapter(child: _buildHero(context, isDark, primary, size)),

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
                      _buildMissionCard(isDark, primary),
                      const Gap(28),
                      _buildStatsRow(isDark, primary),
                      const Gap(38),
                      _buildSectionTitle('What We Offer', isDark),
                      const Gap(4),
                      _buildFeatureGrid(isDark, primary),
                      const Gap(20),
                      _buildSectionTitle('Built & Maintained By', isDark),
                      const Gap(14),
                      _buildTeamSection(isDark, primary),
                      const Gap(28),
                      _buildSectionTitle('Connect With Us', isDark),
                      const Gap(14),
                      _buildSocialLinks(isDark, primary),
                      const Gap(28),
                      _buildVersionFooter(isDark, primary),
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

  Widget _buildHero(
    BuildContext context,
    bool isDark,
    Color primary,
    Size size,
  ) {
    final parallax = (_scrollOffset * 0.4).clamp(0.0, 80.0);

    return ScaleTransition(
      scale: _heroScale,
      child: FadeTransition(
        opacity: _heroFade,
        child: SizedBox(
          height: size.height * 0.42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Gradient background
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, -parallax),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary,
                          primary.withValues(alpha: 0.7),
                          primary.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        ..._buildDecoCircles(primary),

                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 8,
                          child: IconButton(
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // Center content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Gap(32),
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                              const Gap(18),
                              const Text(
                                'Social App',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const Gap(6),
                              Text(
                                'Connecting people, building communities',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                left: 0,
                right: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecoCircles(Color primary) {
    return [
      Positioned(
        top: -60,
        right: -40,
        child: _decoCircle(180, Colors.white.withValues(alpha: 0.06)),
      ),
      Positioned(
        bottom: 20,
        left: -60,
        child: _decoCircle(200, Colors.white.withValues(alpha: 0.05)),
      ),
      Positioned(
        top: 30,
        left: 40,
        child: _decoCircle(80, Colors.white.withValues(alpha: 0.08)),
      ),
      Positioned(
        bottom: 60,
        right: 30,
        child: _decoCircle(60, Colors.white.withValues(alpha: 0.07)),
      ),
    ];
  }

  Widget _decoCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildMissionCard(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.08),
            primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const Gap(10),
              Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Gap(14),
          Text(
            'We believe meaningful connections change lives. Our platform is built to bring people closer — through conversations, shared moments, and real-time experiences that matter.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color primary) {
    final stats = [
      ('50K+', 'Users'),
      ('1M+', 'Messages'),
      ('200K+', 'Posts'),
      ('99.9%', 'Uptime'),
    ];
    return Row(
      children:
          stats.map((s) {
            final isLast = s == stats.last;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : 10),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      s.$1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDark, Color primary) {
    final height = MediaQuery.sizeOf(context).height;
    final features = [
      (
        Icons.chat_bubble_rounded,
        'Real-time Chats',
        'Instant messaging with read receipts',
      ),
      (Icons.call_rounded, 'HD Voice & Video', 'Crystal clear calls anytime'),
      (Icons.people_alt_rounded, 'Group Chats', 'Connect with communities'),
      (Icons.auto_stories_rounded, 'Stories', 'Share your daily moments'),
      (
        Icons.notifications_active_rounded,
        'Smart Alerts',
        'Never miss what matters',
      ),
      (Icons.shield_rounded, 'Privacy First', 'Your data stays yours'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: height * 0.148,
        // mainAxisExtent: 130,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final (icon, title, desc) = features[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + i * 60),
          curve: Curves.easeOut,
          builder:
              (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - v)),
                  child: child,
                ),
              ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.grey.shade200,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: primary, size: 18),
                ),
                const Gap(10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const Gap(3),
                Expanded(
                  child: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamSection(bool isDark, Color primary) {
    final heroTag = 'profile_image_ahmed';
    final team = [
      _TeamMember(
        name: 'Ahmed Atef',
        role: 'Flutter Developer',
        image: AppImages.devPersonnalImg,
        color: Colors.purple.withValues(alpha: 0.85),
      ),
    ];

    return Column(
      children:
          team.asMap().entries.map((entry) {
            final i = entry.key;
            final member = entry.value;
            final isLast = i == team.length - 1;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + i * 80),
              curve: Curves.easeOut,
              builder:
                  (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - v)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.fullScreenImageViewRoute,
                          arguments: {
                            'url': member.image,
                            'tag': heroTag,
                            'isAsset': true,
                          },
                        );
                      },
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Hero(
                          tag: heroTag,
                          child: ClipOval(
                            child: Image.asset(
                              member.image,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Gap(3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: member.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: member.color.withValues(alpha: 0.4),
                                width: .8,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF7C3AED),
                                  const Color(0xFFEC4899),
                                ],
                              ),
                            ),
                            child: Text(
                              member.role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: member.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSocialLinks(bool isDark, Color primary) {
    final links = [
      _SocialLink(
        // icon: Icons.public_rounded,
        icon: FontAwesomeIcons.globe,
        label: 'Website',
        value: 'www.social-media-app.com',
        url: 'https://github.com/Ahmedatef5O5/Social-Media-App',
        color: Colors.blue,
      ),
      _SocialLink(
        // icon: Icons.mail_outline_rounded,
        icon: FontAwesomeIcons.envelope,
        label: 'Email',
        value: 'ahmedateif0@gmail.com',
        url:
            'mailto:ahmedateif0@gmail.com'
            '?subject=Contact%20from%20Social%20App'
            '&body=Hello%20Ahmed,',
        color: Colors.green,
      ),
      _SocialLink(
        // icon: Icons.code_rounded,
        icon: FontAwesomeIcons.github,

        label: 'GitHub',
        value: 'github.com/Ahmedatef5O5',
        url: 'https://github.com/Ahmedatef5O5',
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Column(
        children:
            links.asMap().entries.map((entry) {
              final i = entry.key;
              final link = entry.value;
              final isLast = i == links.length - 1;
              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      HapticFeedback.selectionClick();

                      if (link.label == 'Email') {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'ahmedateif0@gmail.com',
                          queryParameters: {
                            'subject': 'Contact from Social App',
                            'body': 'Hello Ahmed,',
                          },
                        );

                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );

                        return;
                      }

                      final uri = Uri.parse(link.url);
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: link.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(link.icon, color: link.color, size: 18),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  link.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  link.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? Colors.white38
                                            : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 15,
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 68,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade200,
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildVersionFooter(bool isDark, Color primary) {
    return Column(
      children: [
        Divider(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.people_alt_rounded, color: primary, size: 14),
            ),
            const Gap(8),
            Text(
              'Social App',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        const Gap(8),
        Text(
          'Version 1.0.0  •  Made with ❤️',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
        ),
        const Gap(6),
        Text(
          '© ${DateTime.now().year} Social App. All rights reserved.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        const Gap(20),
      ],
    );
  }
}

class _TeamMember {
  final String name, role;
  final String image;
  final Color color;
  const _TeamMember({
    required this.name,
    required this.role,
    required this.image,
    required this.color,
  });
}

class _SocialLink {
  final IconData icon;
  final String label, value, url;
  final Color color;
  const _SocialLink({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
    required this.color,
  });
}
