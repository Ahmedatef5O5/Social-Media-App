import 'package:flutter/widgets.dart';

/// Design tokens for standardized spacing, margins, and paddings across the application.
/// 
/// Built on a 4px mathematical scale. Avoid using arbitrary magic numbers in widgets.
abstract final class AppSpacing {
  // --- Raw Spacing Tokens ---
  
  /// 0px - Reset / No spacing
  static const double space0 = 0.0;

  /// 2px - Hairline gaps, tight inline icon/text spacing
  static const double space1 = 2.0;

  /// 4px - Micro spacing, badge internal padding, tight layout offsets
  static const double space2 = 4.0;

  /// 6px - Compact list item gaps
  static const double space3 = 6.0;

  /// 8px - Standard inter-element spacing, grid gaps, small padding
  static const double space4 = 8.0;

  /// 12px - Section spacing, avatar-to-text gap, compact card padding
  static const double space5 = 12.0;

  /// 16px - Base standard content padding, card internal padding
  static const double space6 = 16.0;

  /// 20px - Screen horizontal margins, bottom sheet content horizontal padding
  static const double space7 = 20.0;

  /// 24px - Large section separation, dialog content padding
  static const double space8 = 24.0;

  /// 32px - Major section breaks, empty state padding
  static const double space9 = 32.0;

  /// 40px - Major layout divisions
  static const double space10 = 40.0;

  /// 48px - Large hero section spacing
  static const double space11 = 48.0;

  /// 64px - Maximum screen-level breathing room
  static const double space12 = 64.0;

  // --- Convenience EdgeInsets ---

  /// All sides: 4px
  static const EdgeInsets p4 = EdgeInsets.all(space2);

  /// All sides: 8px
  static const EdgeInsets p8 = EdgeInsets.all(space4);

  /// All sides: 12px
  static const EdgeInsets p12 = EdgeInsets.all(space5);

  /// All sides: 16px (Standard card/container padding)
  static const EdgeInsets p16 = EdgeInsets.all(space6);

  /// All sides: 20px
  static const EdgeInsets p20 = EdgeInsets.all(space7);

  /// All sides: 24px (Standard dialog padding)
  static const EdgeInsets p24 = EdgeInsets.all(space8);

  /// Standard screen horizontal padding: 20px
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: space7);

  /// Standard card internal padding: 16px
  static const EdgeInsets cardPadding = EdgeInsets.all(space6);

  /// Standard bottom sheet content padding: horizontal 20px, top 12px, bottom 24px
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(space7, space5, space7, space8);

  /// Standard dialog content padding: 24px
  static const EdgeInsets dialogPadding = EdgeInsets.all(space8);
}
