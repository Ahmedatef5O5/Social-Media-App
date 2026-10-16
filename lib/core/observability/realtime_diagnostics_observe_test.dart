import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/observability/crash_reporter.dart';
import 'package:social_media_app/core/observability/observability.dart';
import 'package:social_media_app/core/observability/realtime_diagnostics.dart';

void main() {
  late RecordingCrashReporter reporter;
  late RealtimeDiagnostics diagnostics;

  const live = ChannelPhase.subscribed;

  setUp(() async {
    Observability.resetForTest();
    RealtimeDiagnostics.resetForTest();
    reporter = RecordingCrashReporter();
    await obs.attachReporter(
      reporter,
      environment: 'test',
      appVersion: '1.0.0',
      buildNumber: '2',
    );
    diagnostics = RealtimeDiagnostics.instance;
  });

  test('unknown live channels are registered with the given owner', () {
    diagnostics.observe(const [
      ObservedChannel('realtime:a', live),
    ], owner: 'u1');

    expect(diagnostics.activeCount, 1);
    expect(diagnostics.recordFor('realtime:a')?.ownerUserId, 'u1');
    expect(reporter.customKeys['realtime_active_channels'], 1);
  });

  test('a null owner registers nothing', () {
    diagnostics.observe(const [
      ObservedChannel('realtime:a', live),
    ], owner: null);
    expect(diagnostics.activeCount, 0);
  });

  test('records are removed when the SDK no longer holds the channel', () {
    diagnostics.observe(const [
      ObservedChannel('realtime:a', live),
    ], owner: 'u1');
    diagnostics.observe(const [], owner: 'u1');

    expect(diagnostics.activeCount, 0);
  });

  test('a channel that survives an account switch is flagged as a zombie', () {
    const channels = [ObservedChannel('realtime:a', live)];
    diagnostics.observe(channels, owner: 'u1');
    diagnostics.observe(channels, owner: 'u2');

    final zombies = diagnostics.detectZombies('u2');

    expect(zombies.map((z) => z.topic), ['realtime:a']);
    expect(reporter.errors, hasLength(1));
  });

  test('an explicit registration keeps its owner and matches the SDK topic '
      'with or without the "realtime:" prefix', () {
    diagnostics.onChannelCreated('presence_scope_1', ownerUserId: 'u1');
    diagnostics.onChannelSubscribed('presence_scope_1');

    diagnostics.observe(const [
      ObservedChannel('realtime:presence_scope_1', live),
    ], owner: 'u2');

    expect(diagnostics.activeCount, 1);
    expect(diagnostics.recordFor('presence_scope_1')?.ownerUserId, 'u1');
  });

  test('duplicate live topics are reported once, not on every sample', () {
    const dup = [
      ObservedChannel('realtime:a', live),
      ObservedChannel('realtime:a', live),
    ];
    diagnostics.observe(dup, owner: 'u1');
    diagnostics.observe(dup, owner: 'u1');

    expect(reporter.errors, hasLength(1));
  });

  test('a duplicate is reported again after it was resolved and recurs', () {
    const dup = [
      ObservedChannel('realtime:a', live),
      ObservedChannel('realtime:a', live),
    ];
    diagnostics.observe(dup, owner: 'u1');
    diagnostics.observe(const [
      ObservedChannel('realtime:a', live),
    ], owner: 'u1');
    diagnostics.observe(dup, owner: 'u1');

    expect(reporter.errors, hasLength(2));
  });

  test('a closed channel is not counted as active', () {
    diagnostics.observe(const [
      ObservedChannel('realtime:a', live),
    ], owner: 'u1');
    diagnostics.observe(const [
      ObservedChannel('realtime:a', ChannelPhase.closed),
    ], owner: 'u1');

    expect(diagnostics.activeCount, 0);
  });

  test('pressure is reported once per excursion', () {
    final many = [
      for (var i = 0; i <= RealtimeDiagnostics.suspiciousChannelCount; i++)
        ObservedChannel('realtime:t$i', live),
    ];
    diagnostics.observe(many, owner: 'u1');
    diagnostics.observe(many, owner: 'u1');

    final pressure =
        reporter.errors
            .where((e) => e.error is RealtimeChannelPressure)
            .toList();
    expect(pressure, hasLength(1));
  });
}
