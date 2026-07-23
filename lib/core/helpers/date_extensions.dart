extension SupabaseDateParsing on String {
  DateTime toUtcFromSupabase() {
    final parsed = DateTime.parse(this);
    return parsed.isUtc ? parsed : parsed.toUtc();
  }
}
