import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';

class StoryColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const StoryColorPicker({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 28),
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (_, i) {
          final color = colors[i];

          return GestureDetector(
            onTap: () => onSelect(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border:
                    selected == color
                        ? Border.all(color: AppColors.white, width: 3)
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
