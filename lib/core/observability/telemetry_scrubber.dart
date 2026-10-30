/// Removes personal data from free text BEFORE it leaves the device.
///
/// Used by the incident pipeline (`IncidentReporter`, `OverflowFilter`). It is
/// a best-effort safety net for exception messages we do not control (for
/// example a `PostgrestException` that echoes an e-mail address). The primary
/// defence is still "never forward raw text that did not need to be forwarded".
class TelemetryScrubber {
  TelemetryScrubber._();

  /// Dart package name of the app; used to recognise "user code" frames.
  static const String appPackage = 'social_media_app';

  static final RegExp _jwt = RegExp(
    r'eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]*',
  );

  /// `Bearer abc...` or `token=abc` / `password: abc` style assignments.
  static final RegExp _secretAssignment = RegExp(
    r'bearer\s+[^\s,;)\]}]+'
    r'|(apikey|api_key|token|authorization|password|secret)\s*[=:]\s*'
    r'[^\s,;)\]}]+',
    caseSensitive: false,
  );

  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );

  /// Absolute developer-machine path to this project's `lib/` folder.
  static final RegExp _absoluteLibPath = RegExp(r'file:///[^\s)]*?/lib/');

  static final RegExp _url = RegExp(r'''https?://[^\s)\]}>"']+''');

  static final RegExp _uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}',
  );

  static final RegExp _longDigits = RegExp(r'\d{6,}');

  static final RegExp _anyDigits = RegExp(r'\d+');

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Returns [input] with tokens, e-mails, URL query strings / fragments,
  /// UUIDs and long digit runs (phone numbers, ids) replaced by placeholders,
  /// truncated to [maxLength] characters. Newlines are preserved.
  static String scrub(String? input, {int maxLength = 500}) {
    if (input == null || input.isEmpty) return '';
    var text = input;
    text = text.replaceAll(_jwt, '<jwt>');
    text = text.replaceAllMapped(
      _secretAssignment,
      (m) =>
          m.group(1) == null ? 'bearer <redacted>' : '${m.group(1)}=<redacted>',
    );
    text = text.replaceAll(_email, '<email>');
    text = text.replaceAll(_absoluteLibPath, 'package:$appPackage/');
    text = text.replaceAllMapped(_url, (m) {
      final url = m.group(0)!;
      final cut = url.indexOf(RegExp(r'[?#]'));
      return cut == -1 ? url : url.substring(0, cut);
    });
    text = text.replaceAll(_uuid, '<uuid>');
    text = text.replaceAll(_longDigits, '<n>');
    return truncate(text, maxLength);
  }

  /// Scrubs a single-line value (route names, labels) and collapses whitespace.
  static String scrubLine(String? input, {int maxLength = 100}) {
    final collapsed =
        scrub(
          input,
          maxLength: maxLength * 4,
        ).replaceAll(_whitespace, ' ').trim();
    return truncate(collapsed, maxLength);
  }

  /// Scrubs then replaces EVERY digit run with `#`, so that messages that
  /// differ only by a counter or a duration group into one fingerprint.
  static String normalizeForFingerprint(String? input, {int maxLength = 200}) {
    final scrubbed = scrubLine(input, maxLength: maxLength * 2);
    return truncate(scrubbed.replaceAll(_anyDigits, '#'), maxLength);
  }

  static String truncate(String text, int maxLength) =>
      text.length <= maxLength ? text : text.substring(0, maxLength);
}
