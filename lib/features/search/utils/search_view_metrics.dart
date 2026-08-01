// Single source of truth for spacing across the entire Search view.

class SearchViewMetrics {
  const SearchViewMetrics._();

  /// Horizontal inset used by every list/grid in the Search view.
  static const double horizontalPadding = 16;

  /// Vertical gap between the TabBar and the first item of any tab.
  static const double topGap = 12;

  /// Trailing space after the last item of any tab (safe scroll room).
  static const double bottomGap = 24;

  /// Gap between consecutive items in a vertical list (posts, accounts).
  static const double itemGap = 14;
}
