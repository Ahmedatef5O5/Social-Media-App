extension ByteSizeFormatting on int {
  String get asReadableSize {
    if (this <= 0) return '';
    final mb = this / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
    return '${(this / 1024).toStringAsFixed(0)} KB';
  }
}
