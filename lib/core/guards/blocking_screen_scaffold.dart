import 'package:flutter/material.dart';

/// Shared frame of the three blocking screens: opaque, absorbs touches, is its
/// own semantics route (screen readers announce it and skip what is behind),
/// and centres an icon + title + body + actions column.
///
/// Back-button blocking lives in `SystemControlService.attachBackBlocker`;
/// `PopScope` here would be useless because this widget is an overlay, not a
/// route.
class BlockingScreenScaffold extends StatelessWidget {
  const BlockingScreenScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = iconColor ?? theme.primaryColor;

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: theme.scaffoldBackgroundColor,
          ),
          Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 52, color: accent),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Body text style used under the title of every blocking screen.
TextStyle? blockingBodyStyle(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return theme.textTheme.bodyMedium?.copyWith(
    height: 1.45,
    color: isDark ? Colors.white70 : Colors.grey.shade700,
  );
}
