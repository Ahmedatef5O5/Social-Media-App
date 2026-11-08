import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class GroupPolicyOption<T> {
  final T value;
  final IconData icon;
  final String label;
  const GroupPolicyOption({
    required this.value,
    required this.icon,
    required this.label,
  });
}

/// Compact 2/3-segment pill selector with an animated, direction-aware
/// highlight. Labels are single-line and scale down, so it never overflows
/// at 320px with long Arabic labels or a 1.15 text scale.
class GroupPolicyPillSelector<T> extends StatelessWidget {
  final List<GroupPolicyOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  const GroupPolicyPillSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = options.length;
    final index = options
        .indexWhere((o) => o.value == selected)
        .clamp(0, n - 1);
    final enabled = onChanged != null;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional(
                n == 1 ? 0 : -1 + 2 * index / (n - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final o in options)
                  Expanded(
                    child: _Segment<T>(
                      option: o,
                      isSelected: o.value == selected,
                      onTap: enabled ? () => onChanged!(o.value) : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  final GroupPolicyOption<T> option;
  final bool isSelected;
  final VoidCallback? onTap;
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 16, color: color),
              const Gap(4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: context.ls(0),
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
}

/// Title + selector + animated one-line helper caption.
class GroupPolicyBlock<T> extends StatelessWidget {
  final String title;
  final List<GroupPolicyOption<T>> options;
  final T selected;
  final String caption;
  final ValueChanged<T>? onChanged;

  const GroupPolicyBlock({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.caption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: context.ls(0),
          ),
        ),
        const Gap(10),
        GroupPolicyPillSelector<T>(
          options: options,
          selected: selected,
          onChanged: onChanged,
        ),
        const Gap(8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            caption,
            key: ValueKey(caption),
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
              letterSpacing: context.ls(0),
            ),
          ),
        ),
      ],
    );
  }
}
