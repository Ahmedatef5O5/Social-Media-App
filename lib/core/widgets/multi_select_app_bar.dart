import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MultiSelectAction {
  final IconData icon;
  final Color? color;
  final String? tooltip;
  final VoidCallback onPressed;

  const MultiSelectAction({
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });
}

class MultiSelectChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final List<MultiSelectAction> actions;

  const MultiSelectChatAppBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: kToolbarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: primary),
                onPressed: onCancel,
                tooltip: 'Cancel selection',
              ),
              const Gap(4),
              Text(
                '$selectedCount',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              for (final action in actions)
                IconButton(
                  icon: Icon(action.icon, color: action.color ?? primary),
                  onPressed: action.onPressed,
                  tooltip: action.tooltip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
