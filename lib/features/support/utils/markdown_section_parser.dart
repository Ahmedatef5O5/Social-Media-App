import '../models/policy_section.dart';

class MarkdownSectionParser {
  static List<PolicySection> parse(String markdown) {
    final lines = markdown.split('\n');
    final sections = <PolicySection>[];
    String currentTitle = '';
    final buffer = StringBuffer();

    void flush() {
      final body = buffer.toString().trim();
      if (body.isNotEmpty) {
        sections.add(PolicySection(title: currentTitle, body: body));
      }
      buffer.clear();
    }

    final headingPattern = RegExp(r'^##\s+(.*)');

    for (final line in lines) {
      final match = headingPattern.firstMatch(line);
      if (match != null) {
        flush();
        currentTitle = match.group(1)!.trim();
      } else {
        buffer.writeln(line);
      }
    }
    flush();

    return sections;
  }
}
