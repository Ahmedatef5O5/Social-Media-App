import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'settings_item_data.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<SettingsItemData> items;
  final int delay;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay * 80),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 6),
            child: Row(
              children: [
                Icon(icon, size: 14, color: primary),
                const Gap(6),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
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
                        : Colors.black.withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
            child: Column(
              children:
                  items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isLast = idx == items.length - 1;
                    return _buildSettingsItem(item, isDark, primary, isLast);
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    SettingsItemData item,
    bool isDark,
    Color primary,
    bool isLast,
  ) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap:
              item.toggle == null
                  ? () {
                    HapticFeedback.selectionClick();
                    item.onTap?.call();
                  }
                  : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, color: primary, size: 18),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const Gap(2),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.toggle != null)
                  Transform.scale(
                    scale: 0.85,
                    child: CupertinoSwitch(
                      value: item.toggle!,
                      activeTrackColor: primary,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        item.onToggle?.call(v);
                      },
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
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
                    : Colors.black.withValues(alpha: 0.05),
          ),
      ],
    );
  }
}
