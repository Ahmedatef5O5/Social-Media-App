import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/ai_usage_cubit/ai_usage_cubit.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class AiUsageCard extends StatelessWidget {
  const AiUsageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiUsageCubit, AiUsageState>(
      builder: (context, usage) {
        final fraction = usage.usedFraction;
        final percentLabel =
            fraction != null ? '${(fraction * 100).round()}%' : '—';
        final usedLabel =
            usage.used != null && usage.effectiveUserLimit != null
                ? '${usage.used} / ${usage.effectiveUserLimit}'
                : '—';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.todaysAiUsage,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (usage.activeProvider != null)
                      Text(
                        '${usage.activeProvider} • ${usage.activeModel ?? ''}',
                      ),
                    if (usage.bonusGranted != null &&
                        usage.bonusGranted! > 0) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          context.l10n.bonus2(usage.bonusGranted ?? 0),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.usedOfYourDaily(
                    percentLabel,
                    usage.effectiveUserLimit ?? '—',
                    usedLabel,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: fraction ?? 0),
              ],
            ),
          ),
        );
      },
    );
  }
}
