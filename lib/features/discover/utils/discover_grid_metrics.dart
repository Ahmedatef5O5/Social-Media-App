/// Single source of truth for the 2-column Discover grid layout,
/// shared by DiscoverView, AccountsTabView, and DiscoverPeopleSearchView.
///
/// NOTE: switched from a fixed-height SliverGrid to a Masonry layout
/// (see usages) because card content height varies significantly
/// (name/username/mutuals/badges are all optional) — a fixed height
/// either overflows content-heavy cards or leaves large empty gaps on
/// sparse ones. Masonry lets each card size to its own content.
class DiscoverGridMetrics {
  const DiscoverGridMetrics._();

  static const int crossAxisCount = 2;
  static const double crossAxisSpacing = 12;
  static const double mainAxisSpacing = 12;
}
