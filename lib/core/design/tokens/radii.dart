import 'package:flutter/widgets.dart';

/// Design tokens for standardized border radiuses across all surfaces and components.
/// 
/// Strictly use these predefined radiuses instead of arbitrary values.
abstract final class AppRadii {
  // --- Raw Radius Values (double) ---

  /// 0.0 - Sharp edges
  static const double rawNone = 0.0;

  /// 4.0 - Code blocks, tiny badges, micro elements
  static const double rawXs = 4.0;

  /// 8.0 - Small buttons, small chips, image thumbnails
  static const double rawSm = 8.0;

  /// 12.0 - Standard buttons, text input fields, small cards, toast notifications
  static const double rawMd = 12.0;

  /// 16.0 - Standard post/feed cards, discover cards, bottom sheets
  static const double rawLg = 16.0;

  /// 20.0 - Modals, confirmation dialogs
  static const double rawXl = 20.0;

  /// 24.0 - Floating action containers, expanded bottom sheets
  static const double raw2xl = 24.0;

  /// 9999.0 - Avatars, pills, search bars, floating nav bar, full-circle elements
  static const double rawFull = 9999.0;

  // --- BorderRadius Constants ---

  /// 0px border radius
  static const BorderRadius radiusNone = BorderRadius.zero;

  /// 4px circular border radius (code blocks, tiny badges)
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(rawXs));

  /// 8px circular border radius (small buttons, chips, thumbnails)
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(rawSm));

  /// 12px circular border radius (standard buttons, input fields, small cards)
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(rawMd));

  /// 16px circular border radius (cards, bottom sheets, containers)
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(rawLg));

  /// 20px circular border radius (modals, dialogs)
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(rawXl));

  /// 24px circular border radius (floating containers, expanded sheets)
  static const BorderRadius radius2xl = BorderRadius.all(Radius.circular(raw2xl));

  /// 9999px pill / circular border radius (pills, avatars, floating nav bar)
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(rawFull));

  // --- Directional / Specialized Radiuses ---

  /// Top rounded corners (16px) - standard bottom sheet
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(rawLg),
  );

  /// Top rounded corners (24px) - expanded bottom sheet
  static const BorderRadius bottomSheetExpanded = BorderRadius.vertical(
    top: Radius.circular(raw2xl),
  );
}
