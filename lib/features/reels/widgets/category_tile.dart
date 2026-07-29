import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../model/reel_category.dart';

class CategoryTile extends StatefulWidget {
  final ReelCategoryOption category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutQuad,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuart,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient:
                widget.isSelected
                    ? LinearGradient(
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.12),
                        AppColors.primaryColor.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color:
                widget.isSelected
                    ? null
                    : (isDark
                        ? Colors.grey.withValues(alpha: 0.06)
                        : Colors.white),
            border: Border.all(
              color:
                  widget.isSelected
                      ? AppColors.primaryColor.withValues(alpha: 0.7)
                      : colorScheme.outline.withValues(alpha: 0.12),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow:
                widget.isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedSlide(
                  offset:
                      widget.isSelected ? const Offset(0, -0.03) : Offset.zero,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutQuart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder:
                            (child, animation) => FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            ),
                        child: Icon(
                          widget.category.icon,
                          key: ValueKey('${widget.isSelected}'),
                          color:
                              widget.isSelected
                                  ? AppColors.primaryColor
                                  : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                          size: widget.isSelected ? 32 : 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutQuart,
                        style: TextStyle(
                          color:
                              widget.isSelected
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.9,
                                  ),
                          fontWeight:
                              widget.isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.3,
                          fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                        ),
                        child: Text(widget.category.label),
                      ),
                    ],
                  ),
                ),
              ),

              if (widget.isSelected)
                Positioned(
                  top: 14,
                  right: 14,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
