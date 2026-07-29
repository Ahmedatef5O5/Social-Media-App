import 'package:flutter/material.dart';
import '../models/content_privacy.dart';

class PrivacyOptionCard extends StatelessWidget {
  final ContentPrivacy value;
  final ContentPrivacy currentValue;
  final String title;
  final String subtitle;
  final IconData icon;

  const PrivacyOptionCard({
    super.key,
    required this.value,
    required this.currentValue,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primary : Colors.transparent,
              width: 2,
            ),
            color:
                isSelected
                    ? primary.withValues(alpha: 0.08)
                    : (isDark
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primary
                          : (isDark
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.1)),
                  shape: BoxShape.circle,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child: Icon(
                  icon,
                  color:
                      isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primary : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected
                            ? primary
                            : Colors.grey.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
