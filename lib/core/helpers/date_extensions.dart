extension SupabaseDateParsing on String {
  DateTime toLocalFromSupabase() {
    String dateString = this;
    if (!dateString.endsWith('Z')) {
      dateString += 'Z';
    }
    return DateTime.parse(dateString).toLocal();
  }
}
