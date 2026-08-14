import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import '../entities/ai_active_provider.dart';

class AiUsageQuotaCard extends StatelessWidget {
  const AiUsageQuotaCard({super.key});

  String _resetTimeLabel() {
    final nowUtc = DateTime.now().toUtc();
    final nextUtcMidnight = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
    ).add(const Duration(days: 1));
    return DateFormat.jm().format(nextUtcMidnight.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return BlocBuilder<AiPreferencesCubit, AiPreferencesState>(
      buildWhen: (previous, current) => previous.usage != current.usage,
      builder: (context, state) {
        final usage = state.usage;
        final fraction =
            usage.dailyLimit == 0
                ? 0.0
                : (usage.usedToday / usage.dailyLimit).clamp(0.0, 1.0);
        final percentage = (fraction * 100).round();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.22 : 0.16),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.query_stats_rounded,
                      color: primary,
                      size: 18,
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      "Today's AI Usage",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (usage.isPlaceholder) _EstimatedChip(primary: primary),
                ],
              ),
              const Gap(14),
              // تم وضع مزود الخدمة وشريحة البونص في صف واحد
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white12
                                : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      key: ValueKey(
                        '${usage.activeProvider.wireValue}_${usage.activeModelId ?? ''}',
                      ),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          usage.activeProvider.icon,
                          size: 12,
                          color: primary,
                        ),
                        const Gap(6),
                        Text(
                          usage.activeProvider.displayName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        if (usage.activeModelId != null) ...[
                          const Gap(5),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black26,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(5),
                          Text(
                            usage.activeModelId!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (usage.bonusGranted > 0)
                    _BonusChip(bonus: usage.bonusGranted),
                ],
              ),
              const Gap(16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$percentage% ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: 'used of your ${usage.dailyLimit} daily requests',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: fraction),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedFraction, _) {
                        return FractionallySizedBox(
                          widthFactor: animatedFraction,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withValues(alpha: 0.65),
                                  primary,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Gap(14),
              Row(
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      'Resets at ${_resetTimeLabel()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EstimatedChip extends StatelessWidget {
  final Color primary;
  const _EstimatedChip({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Estimated',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  final int bonus;
  const _BonusChip({required this.bonus});

  @override
  Widget build(BuildContext context) {
    final color = Colors.teal.shade600;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder:
          (child, animation) =>
              FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey(bonus),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_rounded, size: 11, color: color),
            const Gap(3),
            Text(
              '~$bonus Bonus',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
