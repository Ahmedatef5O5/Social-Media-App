bool matchesSearchQuery(String query, List<String?> fields) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  for (final field in fields) {
    if (field != null && field.toLowerCase().contains(needle)) return true;
  }
  return false;
}
