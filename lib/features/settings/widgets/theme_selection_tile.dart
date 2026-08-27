import 'package:flutter/material.dart';
import '../../../core/themes/models/app_theme_model.dart';
import '../../../core/design/tokens/typography.dart';

class ThemeSelectionTile extends StatelessWidget {
  final AppThemeModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeSelectionTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAppDark = theme.brightness == Brightness.dark;
    final bool isCardDark = item.bgBase.computeLuminance() < 0.5;
    final Color unselectedTextColor =
        isAppDark
            ? Colors.white.withValues(alpha: 0.9)
            : (isCardDark ? Colors.white : Colors.black87);

    final Color tileBg =
        isSelected
            ? (isAppDark
                ? (isCardDark
                    ? item.bgCircle
                    : item.bgCircle.withValues(alpha: 0.4))
                : item.bgCircle)
            : (isAppDark
                ? (isCardDark
                    ? item.bgCircle.withValues(alpha: 0.25)
                    : item.bgCircle.withValues(alpha: 0.15))
                : item.bgCircle.withValues(alpha: 0.45));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? item.primaryColor
                      : (isAppDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.05)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: item.primaryColor.withValues(
                          alpha: isAppDark ? 0.25 : 0.15,
                        ),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : [],
          ),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedScale(
                    scale: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: item.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (isAppDark ? item.bgCircle : item.bgBase)
                                : item.bgCircle.withValues(
                                  alpha:
                                      isCardDark
                                          ? 0.25
                                          : (isAppDark ? 0.3 : 0.75),
                                ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji,
                        style: TextStyle(
                          inherit: false,
                          fontSize: 22,
                          fontWeight: FontWeight.normal,
                          fontFamilyFallback: AppTypography.emojiFontFallback,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.2,
                        color:
                            isSelected
                                ? (isAppDark ? Colors.white : item.primaryColor)
                                : unselectedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
