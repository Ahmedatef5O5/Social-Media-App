import 'package:flutter/widgets.dart';

/// Design tokens for standardized elevation and box shadows.
/// 
/// Replaces heavy, arbitrary drop shadows with subtle, clean elevation levels.
/// Use Level 0 (Flat with outline border) for standard in-flow cards.
abstract final class AppShadows {
  // --- Level 0: Flat (Default for standard cards and list items) ---

  /// Level 0 (Flat): No shadow. Rely on 1px outline border for boundary definition.
  static const List<BoxShadow> level0 = <BoxShadow>[];

  // --- Level 1: Lifted (Hover states, pressed items, slightly elevated surfaces) ---

  /// Level 1 Light: Subtle single/dual layer lift
  static const List<BoxShadow> level1Light = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 3.0,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Level 1 Dark: 1.5x opacity for dark mode visibility
  static const List<BoxShadow> level1Dark = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 3.0,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.09),
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  // --- Level 2: Floating (Floating nav bar, FABs, popovers) ---

  /// Level 2 Light: Soft ambient float
  static const List<BoxShadow> level2Light = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Level 2 Dark
  static const List<BoxShadow> level2Dark = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  // --- Level 3: Overlay (Modals, bottom sheets, dialogs, dropdown menus) ---

  /// Level 3 Light: Distinct elevation overlay
  static const List<BoxShadow> level3Light = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 24.0,
      offset: Offset(0, 8),
    ),
  ];

  /// Level 3 Dark
  static const List<BoxShadow> level3Dark = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.18),
      blurRadius: 24.0,
      offset: Offset(0, 8),
    ),
  ];

  // --- Level 4: Dramatic (Full-screen hero overlays, action drawers) ---

  /// Level 4 Light: Deep cinematic shadow
  static const List<BoxShadow> level4Light = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.16),
      blurRadius: 48.0,
      offset: Offset(0, 16),
    ),
  ];

  /// Level 4 Dark
  static const List<BoxShadow> level4Dark = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.24),
      blurRadius: 48.0,
      offset: Offset(0, 16),
    ),
  ];

  // --- Theme-Aware Helper Methods ---

  /// Returns Level 1 shadows adapted for brightness
  static List<BoxShadow> getLevel1({required bool isDark}) =>
      isDark ? level1Dark : level1Light;

  /// Returns Level 2 shadows adapted for brightness (Floating nav bar, FABs)
  static List<BoxShadow> getLevel2({required bool isDark}) =>
      isDark ? level2Dark : level2Light;

  /// Returns Level 3 shadows adapted for brightness (Dialogs, modals)
  static List<BoxShadow> getLevel3({required bool isDark}) =>
      isDark ? level3Dark : level3Light;

  /// Returns Level 4 shadows adapted for brightness
  static List<BoxShadow> getLevel4({required bool isDark}) =>
      isDark ? level4Dark : level4Light;
}
