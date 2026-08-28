/// Design tokens for standardized component dimensions, sizes, and layout constraints.
/// 
/// Enforces consistent component sizing across all 23 features.
abstract final class AppDimensions {
  // --- Buttons ---

  /// 48px - Standard primary/secondary CTA button height
  static const double buttonHeight = 48.0;

  /// 36px - Compact in-card CTA button height (e.g. "Add Friend", "Follow")
  static const double buttonHeightSmall = 36.0;

  /// 120px - Minimum width for standard CTA buttons
  static const double buttonMinWidth = 120.0;

  // --- Inputs & Form Fields ---

  /// 48px - Standard single-line text input field height
  static const double inputHeight = 48.0;

  /// 44px - Standard search bar height (Discover, Chat list, Search screen)
  static const double searchBarHeight = 44.0;

  // --- Navigation & App Bars ---

  /// 56px - Standard top AppBar height
  static const double appBarHeight = 56.0;

  /// 56px - Standard floating glass bottom navigation bar height
  static const double navBarHeight = 56.0;

  /// 40px - Standard tab bar height
  static const double tabBarHeight = 40.0;

  /// 36px - Standard bottom sheet drag handle width
  static const double bottomSheetHandleWidth = 36.0;

  /// 4px - Standard bottom sheet drag handle height
  static const double bottomSheetHandleHeight = 4.0;

  // --- Avatars ---

  /// 32px - Small avatar (mentions suggestions, dense lists)
  static const double avatarSmall = 32.0;

  /// 40px - Medium avatar (post author row, standard chat tiles)
  static const double avatarMedium = 40.0;

  /// 48px - Large avatar (user cards, expanded chat headers)
  static const double avatarLarge = 48.0;

  /// 72px - Extra Large avatar (discover person cards, profile header preview)
  static const double avatarXl = 72.0;

  /// 96px - Hero avatar (full profile view)
  static const double avatarHero = 96.0;

  /// 56px - Story circle avatar diameter
  static const double storyCircleSize = 56.0;

  /// 2px - Story gradient ring border width
  static const double storyRingWidth = 2.0;

  /// 2px - Gap between story ring and avatar image
  static const double storyRingGap = 2.0;

  // --- Icons ---

  /// 16px - Small inline icon, status indicators
  static const double iconSmall = 16.0;

  /// 20px - Standard in-card action icon (Like, Comment, Share, Save)
  static const double iconMedium = 20.0;

  /// 24px - Large navigation, app bar action icon
  static const double iconLarge = 24.0;

  // --- Badges, Chips & Dividers ---

  /// 20px - Minimum badge diameter (unread counters)
  static const double badgeSizeMin = 20.0;

  /// 14px - Online / offline status dot indicator diameter
  static const double onlineDotSize = 14.0;

  /// 28px - Compact chip / tag height
  static const double chipHeight = 28.0;

  /// 32px - Filter pill button height
  static const double filterPillHeight = 32.0;

  /// 0.5px - Standard hairline divider thickness
  static const double dividerThickness = 0.5;

  /// 1.0px - Standard resting card/surface outline border width
  static const double borderWidthDefault = 1.0;

  /// 2.0px - Focused input field border width
  static const double borderWidthFocused = 2.0;

  // --- Chat & Glassmorphism ---

  /// 75% (0.75) - Maximum width fraction of screen for chat bubbles
  static const double chatBubbleMaxWidthFraction = 0.75;

  /// 16.0 - Standard backdrop blur sigma (X and Y) for glassmorphism
  static const double glassBlurSigma = 16.0;

  /// 0.70 - Light mode surface opacity for glassmorphism
  static const double glassSurfaceOpacityLight = 0.70;

  /// 0.65 - Dark mode surface opacity for glassmorphism
  static const double glassSurfaceOpacityDark = 0.65;

  /// 0.12 - Light mode border opacity for glassmorphism
  static const double glassBorderOpacityLight = 0.12;

  /// 0.06 - Dark mode border opacity for glassmorphism
  static const double glassBorderOpacityDark = 0.06;
}
