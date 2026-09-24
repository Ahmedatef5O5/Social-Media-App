// Critical-path coverage gate.
//
// Run:  dart run tool/check_coverage.dart
// Reads coverage/lcov.info produced by `flutter test --coverage`.
//
// WHY NOT A GLOBAL PERCENTAGE
// ───────────────────────────
// A single number over 130k lines is a vanity metric. 40% global can mean
// every model's `toString` is covered and `MessageReconciler` is not. This
// gate names the files where a defect corrupts data or leaks one account's
// content into another, and requires a real number on each of them.
//
// Files not listed here are not gated at all. That is intentional: a gate
// that blocks unrelated work gets disabled within a month.

import 'dart:io';

/// path prefix (as it appears in lcov `SF:` lines) → minimum line coverage.
const Map<String, double> criticalPaths = {
  // P0 — every chat message in the app passes through this.
  'lib/core/messaging/message_reconciler.dart': 90.0,

  // P0 — decides what reaches Crashlytics at all.
  'lib/core/observability/error_category.dart': 80.0,
  'lib/core/observability/observability.dart': 70.0,
  'lib/core/observability/realtime_diagnostics.dart': 80.0,

  // P0 — conversation identity; a bug here mis-keys caches across accounts.
  'lib/core/helpers/chat_helper.dart': 60.0,

  // P1 — feed pagination boundaries (V6 C-03).
  'lib/features/posts/helpers/feed_paginator.dart': 85.0,

  // P1 — the single mapper every user-facing error message comes from.
  'lib/core/errors/supabase_error_mapper.dart': 85.0,

  // P1 — reel player lifecycle (V6 H-05).
  // 'lib/features/reels/services/reel_player_controller_pool.dart': 70.0,
};

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run: flutter test --coverage',
    );
    exit(1);
  }

  final coverage = _parseLcov(file.readAsLinesSync());
  final failures = <String>[];
  final report = StringBuffer();

  report.writeln('');
  report.writeln('Critical-path coverage');
  report.writeln('─' * 78);

  for (final entry in criticalPaths.entries) {
    final measured = coverage[_normalise(entry.key)];

    if (measured == null) {
      failures.add(
        '${entry.key}: NOT PRESENT in lcov.info — no test imports this file',
      );
      report.writeln('  ✗  ${entry.key.padRight(58)} no data');
      continue;
    }

    final percent = measured.percent;
    final ok = percent >= entry.value;
    if (!ok) {
      failures.add(
        '${entry.key}: ${percent.toStringAsFixed(1)}% < '
        '${entry.value.toStringAsFixed(1)}% required',
      );
    }
    report.writeln(
      '  ${ok ? '✓' : '✗'}  ${entry.key.padRight(58)} '
      '${percent.toStringAsFixed(1).padLeft(5)}% '
      '(min ${entry.value.toStringAsFixed(0)}%)',
    );
  }

  report.writeln('─' * 78);
  stdout.write(report.toString());

  if (failures.isEmpty) {
    stdout.writeln('All critical paths meet their threshold.\n');
    exit(0);
  }

  stderr.writeln('\nCoverage gate FAILED:');
  for (final failure in failures) {
    // GitHub Actions renders this as a red annotation on the run.
    stderr.writeln('::error::$failure');
  }
  stderr.writeln(
    '\nReproduce locally:\n'
    '  flutter test --coverage\n'
    '  dart run tool/check_coverage.dart\n',
  );
  exit(1);
}

class _FileCoverage {
  _FileCoverage(this.found, this.hit);
  final int found;
  final int hit;
  double get percent => found == 0 ? 100.0 : (hit / found) * 100.0;
}

String _normalise(String path) => path.replaceAll('\\', '/');

Map<String, _FileCoverage> _parseLcov(List<String> lines) {
  final result = <String, _FileCoverage>{};
  String? current;
  var found = 0;
  var hit = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      current = _normalise(line.substring(3).trim());
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        found++;
        if ((int.tryParse(parts[1]) ?? 0) > 0) hit++;
      }
    } else if (line.trim() == 'end_of_record' && current != null) {
      result[current] = _FileCoverage(found, hit);
      current = null;
    }
  }

  return result;
}
