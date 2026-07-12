import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AboutUsHero extends StatelessWidget {
  final Animation<double> heroScale;
  final Animation<double> heroFade;
  final double scrollOffset;

  const AboutUsHero({
    super.key,
    required this.heroScale,
    required this.heroFade,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final size = MediaQuery.sizeOf(context);
    final parallax = (scrollOffset * 0.4).clamp(0.0, 80.0);

    return ScaleTransition(
      scale: heroScale,
      child: FadeTransition(
        opacity: heroFade,
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
}
