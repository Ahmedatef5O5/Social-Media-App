import 'package:flutter/material.dart';

String formatMediaFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const kb = 1024;
  const mb = kb * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  return '${(bytes / mb).toStringAsFixed(1)} MB';
}

String formatLocalizedMediaFileSize(BuildContext context, int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;

  if (isArabic) {
    if (bytes < kb) return '$bytes بايت';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} كيلوبايت';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} ميجابايت';
    return '${(bytes / gb).toStringAsFixed(1)} جيجابايت';
  }

  return formatMediaFileSize(bytes);
}

String _formatBytesAllowZero(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  return '${(bytes / mb).toStringAsFixed(1)} MB';
}

String formatMediaFileSizeRatio(int? downloadedBytes, int? totalBytes) {
  if (totalBytes == null || totalBytes <= 0) return '';
  final downloaded = (downloadedBytes ?? 0).clamp(0, totalBytes);
  return '${_formatBytesAllowZero(downloaded)} / ${formatMediaFileSize(totalBytes)}';
}

String formatMediaDuration(int? seconds) {
  if (seconds == null || seconds < 0) return '';
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
