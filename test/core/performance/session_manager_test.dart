import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/observability/error_category.dart';
import 'package:social_media_app/core/performance/interceptors/startup_tracker.dart';
import 'package:social_media_app/core/performance/session_manager.dart';

class Sent {
  Sent(this.id, this.startupMs, this.meta);
  final String id;
  final int? startupMs;
  final Map<String, dynamic> meta;
  @override
  String toString() => 'Sent($id, $startupMs, $meta)';
}

/// Everything a SessionManager needs, faked: clock, ids, transport, store,
/// stall ticker, startup frames.
class Rig {
  Rig({InMemorySessionStore? store, this.signedIn = true, int idSeed = 0})
      : store = store ?? InMemorySessionStore() {
    startup = StartupTracker(scheduler: frames.add, stopwatch: () => _Sw());
    manager = SessionManager(
      store: this.store,
      transport: (id, ms, meta) async {
        if (failTransport) throw StateError('offline');
        sent.add(Sent(id, ms, Map<String, dynamic>.from(meta)));
      },
      idGenerator: () => 'id-${idSeed + (++counter)}',
      now: () => clock,
      isSignedIn: () => signedIn,
      deviceMeta: () => {'app_version': '1.2.3', 'build_number': '7', 'platform': 'android'},
      startup: startup,
      stallDetector: MainIsolateStallDetector(
        onStall: (_) => manager.markAnr(),
        now: () => clock,
        scheduler: (i, cb) { stallTick = cb; return () => stallTick = null; },
      ),
      enabled: true,
    );
  }

  final InMemorySessionStore store;
  late final SessionManager manager;
  late final StartupTracker startup;
  DateTime clock = DateTime.utc(2026, 11, 14, 12);
  bool signedIn;
  bool failTransport = false;
  int counter = 0;
  void Function()? stallTick;
  final List<void Function()> frames = [];
  final List<Sent> sent = [];

  void advance(Duration d) => clock = clock.add(d);

  Future<void> settle() async {
    await manager.debugWaitForIdle();
    await manager.persisted;
  }

  Future<void> lifecycle(AppLifecycleState s) async {
    manager.didChangeAppLifecycleState(s);
    await settle();
  }

  Map<String, dynamic> record() => jsonDecode(store.value!) as Map<String, dynamic>;
}

class _Sw implements Stopwatch {
  @override void start() {}
  @override void stop() {}
  @override void reset() {}
  @override Duration get elapsed => const Duration(milliseconds: 900);
  @override int get elapsedMicroseconds => 900000;
  @override int get elapsedMilliseconds => 900;
  @override int get elapsedTicks => 900000;
  @override int get frequency => 1000000;
  @override bool get isRunning => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('session id', () {
    test('is a valid RFC 4122 v4 UUID', () {
      final re = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      for (var i = 0; i < 200; i++) {
        expect(re.hasMatch(generateSessionId()), isTrue);
      }
    });

    test('is deterministic for a seeded Random and unique otherwise', () {
      expect(generateSessionId(Random(1)), generateSessionId(Random(1)));
      final ids = {for (var i = 0; i < 500; i++) generateSessionId()};
      expect(ids.length, 500);
    });
  });

  group('session ID rotation', () {
    test('every app launch gets a NEW id (relaunch with the same store)', () async {
      final store = InMemorySessionStore();
      final a = Rig(store: store, idSeed: 0);
      await a.manager.start();
      await a.settle();
      final first = a.manager.sessionId;

      final b = Rig(store: store, idSeed: 100); // new process, same persisted record
      await b.manager.start();
      await b.settle();
      expect(b.manager.sessionId, isNot(first));
      expect(first, 'id-1');
      expect(b.manager.sessionId, 'id-101');
    });

    test('start() is idempotent', () async {
      final r = Rig();
      await r.manager.start();
      await r.manager.start();
      expect(r.manager.sessionId, 'id-1');
      expect(r.counter, 1);
    });

    test('short stay in background keeps the session', () async {
      final r = Rig();
      await r.manager.start();
      await r.settle();
      await r.lifecycle(AppLifecycleState.paused);
      r.advance(const Duration(minutes: 29));
      await r.lifecycle(AppLifecycleState.resumed);
      expect(r.manager.sessionId, 'id-1');
    });

    test('>= 30 min in background rotates the id, ends the old session, measures a warm start', () async {
      final r = Rig();
      await r.manager.start();
      await r.settle();
      r.sent.clear();

      await r.lifecycle(AppLifecycleState.paused);
      r.advance(const Duration(minutes: 31));
      await r.lifecycle(AppLifecycleState.resumed);

      expect(r.manager.sessionId, 'id-2');
      final ended = r.sent.where((s) => s.id == 'id-1' && s.meta['ended'] == true);
      expect(ended.length, 1);
      expect(r.sent.where((s) => s.id == 'id-2').length, greaterThan(0));

      // the warm start of the new session is measured on the next frame
      expect(r.frames.length, 1);
      r.frames.single();
      await r.settle();
      final warm = r.sent.lastWhere((s) => s.id == 'id-2');
      expect(warm.meta['startup_kind'], 'warm');
      expect(warm.startupMs, 900);
    });

    test('exactly 30 minutes in background already rotates (boundary)', () async {
      final r = Rig();
      await r.manager.start();
      await r.lifecycle(AppLifecycleState.paused);
      r.advance(const Duration(minutes: 30));
      await r.lifecycle(AppLifecycleState.resumed);
      expect(r.manager.sessionId, 'id-2');
    });

    test('inactive (permission dialog) does not count as background', () async {
      final r = Rig();
      await r.manager.start();
      await r.lifecycle(AppLifecycleState.inactive);
      expect(r.manager.isForeground, isTrue);
      expect(r.record()['fg'], true);
    });
  });

  group('heartbeat content', () {
    test('first heartbeat carries base meta and no flags', () async {
      final r = Rig();
      await r.manager.start();
      await r.settle();
      expect(r.sent.length, 1);
      expect(r.sent.single.id, 'id-1');
      expect(r.sent.single.meta, {'app_version': '1.2.3', 'build_number': '7', 'platform': 'android'});
      expect(r.sent.single.startupMs, isNull);
    });

    test('the cold start sample is sent with its kind', () async {
      final r = Rig();
      await r.manager.start();
      r.manager.reportStartup(const StartupSample(StartupKind.cold, Duration(milliseconds: 1840)));
      await r.settle();
      final last = r.sent.last;
      expect(last.startupMs, 1840);
      expect(last.meta['startup_kind'], 'cold');
    });

    test('a cold sample that arrives BEFORE start() is kept and applied', () async {
      final r = Rig();
      r.manager.reportStartup(const StartupSample(StartupKind.cold, Duration(milliseconds: 2100)));
      expect(r.sent, isEmpty);
      await r.manager.start();
      await r.settle();
      expect(r.sent.last.startupMs, 2100);
      expect(r.sent.last.meta['startup_kind'], 'cold');
    });

    test('only the first startup sample of a session counts', () async {
      final r = Rig();
      await r.manager.start();
      r.manager.reportStartup(const StartupSample(StartupKind.cold, Duration(milliseconds: 1000)));
      r.manager.reportStartup(const StartupSample(StartupKind.warm, Duration(milliseconds: 50)));
      await r.settle();
      expect(r.sent.last.startupMs, 1000);
    });

    test('wiring: StartupTracker output reaches the session', () async {
      final r = Rig();
      await r.manager.start();
      r.startup.begin();
      r.startup.attachFirstFrame();
      r.frames.single();
      await r.settle();
      expect(r.sent.last.meta['startup_kind'], 'cold');
    });

    test('flags are sent once set and accumulate', () async {
      final r = Rig();
      await r.manager.start();
      r.manager.markAnr();
      await r.settle();
      expect(r.sent.last.meta['anr'], true);
      r.manager.markCrashed();
      await r.settle();
      expect(r.sent.last.meta['anr'], true);
      expect(r.sent.last.meta['crashed'], true);
      expect(r.sent.last.meta['crash_foreground'], true);
    });

    test('a crash while in background is not a foreground crash', () async {
      final r = Rig();
      await r.manager.start();
      await r.lifecycle(AppLifecycleState.paused);
      r.manager.markCrashed();
      await r.settle();
      expect(r.sent.last.meta['crashed'], true);
      expect(r.sent.last.meta.containsKey('crash_foreground'), isFalse);
    });
  });

  group('delivery when offline / signed out', () {
    test('stays dirty while signed out and is delivered on sign-in', () async {
      final r = Rig(signedIn: false);
      await r.manager.start();
      await r.settle();
      expect(r.sent, isEmpty);
      expect(r.manager.isDirty, isTrue);

      r.signedIn = true;
      r.manager.onAuthChanged();
      await r.settle();
      expect(r.sent.length, 1);
      expect(r.manager.isDirty, isFalse);
    });

    test('a failing transport leaves the session dirty and retries later', () async {
      final r = Rig();
      r.failTransport = true;
      await r.manager.start();
      await r.settle();
      expect(r.manager.isDirty, isTrue);
      r.failTransport = false;
      await r.manager.syncNow();
      expect(r.sent.length, 1);
      expect(r.manager.isDirty, isFalse);
    });

    test('a change that arrives while a sync is running is not lost', () async {
      final r = Rig();
      await r.manager.start();
      await r.settle();
      r.sent.clear();
      r.manager.markAnr();          // starts a sync
      r.manager.markCrashed();      // arrives while it is in flight
      await r.settle();
      final last = r.sent.last;
      expect(last.meta['anr'], true);
      expect(last.meta['crashed'], true);
      expect(r.manager.isDirty, isFalse);
    });

    test('syncNow never throws, even when the transport does', () async {
      final r = Rig();
      r.failTransport = true;
      await r.manager.start();
      await r.manager.syncNow();
    });

    test('a clean, delivered session produces no traffic on resume', () async {
      final r = Rig();
      await r.manager.start();
      await r.settle();
      r.sent.clear();
      await r.lifecycle(AppLifecycleState.paused);
      await r.lifecycle(AppLifecycleState.resumed);
      expect(r.sent, isEmpty);
    });
  });

  group('crash detection', () {
    test('previous process died in the FOREGROUND -> previous session reported as crashed', () async {
      final store = InMemorySessionStore();
      final a = Rig(store: store);
      await a.manager.start();
      await a.settle();
      // process dies here: no pause, no cleanup

      final b = Rig(store: store, idSeed: 100);
      await b.manager.start();
      await b.settle();
      final prev = b.sent.firstWhere((s) => s.id == 'id-1');
      expect(prev.meta['crashed'], true);
      expect(prev.meta['crash_foreground'], true);
      expect(prev.meta['ended'], true);
      expect(b.sent.where((s) => s.id == 'id-101').length, 1);
      expect(b.sent.any((s) => s.id == 'id-101' && s.meta.containsKey('crashed')), isFalse);
    });

    test('previous process was killed in BACKGROUND -> NOT a crash', () async {
      final store = InMemorySessionStore();
      final a = Rig(store: store);
      await a.manager.start();
      await a.settle();
      await a.lifecycle(AppLifecycleState.paused); // clean exit marker

      final b = Rig(store: store, idSeed: 100);
      await b.manager.start();
      await b.settle();
      expect(b.sent.where((s) => s.id == 'id-1'), isEmpty);
    });

    test('a live crash that could not be delivered is reported on next launch', () async {
      final store = InMemorySessionStore();
      final a = Rig(store: store);
      a.failTransport = true;
      await a.manager.start();
      a.manager.markCrashed();
      await a.settle();
      await a.lifecycle(AppLifecycleState.paused); // even if backgrounded afterwards

      final b = Rig(store: store, idSeed: 100);
      await b.manager.start();
      await b.settle();
      final prev = b.sent.firstWhere((s) => s.id == 'id-1');
      expect(prev.meta['crashed'], true);
    });

    test('reports about previous sessions survive while signed out, then drain on sign-in', () async {
      final store = InMemorySessionStore();
      final a = Rig(store: store);
      await a.manager.start();
      await a.settle();

      final b = Rig(store: store, idSeed: 100, signedIn: false);
      await b.manager.start();
      await b.settle();
      expect(b.sent, isEmpty);
      expect(b.manager.pendingReports, 1);

      final c = Rig(store: store, idSeed: 200, signedIn: true); // restart, now signed in
      await c.manager.start();
      await c.settle();
      expect(c.sent.where((s) => s.id == 'id-1' && s.meta['crashed'] == true).length, 1);
      expect(c.manager.pendingReports, 0);
    });

    test('a corrupt persisted record never blocks startup', () async {
      final store = InMemorySessionStore()..value = '{not json';
      final r = Rig(store: store);
      await r.manager.start();
      await r.settle();
      expect(r.manager.sessionId, 'id-1');
    });

    test('the pending list is bounded', () async {
      final store = InMemorySessionStore();
      for (var i = 0; i < 15; i++) {
        final rig = Rig(store: store, idSeed: i * 1000, signedIn: false);
        await rig.manager.start();
        await rig.settle();
      }
      final last = Rig(store: store, idSeed: 99000, signedIn: false);
      await last.manager.start();
      expect(last.manager.pendingReports <= SessionManager.maxPending, isTrue);
    });

    test('SessionCrashReporter: fatal -> crashed, non-fatal -> ignored', () async {
      final r = Rig();
      await r.manager.start();
      final reporter = SessionCrashReporter(manager: r.manager);
      await reporter.recordError(StateError('x'), null, category: ErrorCategory.handledException);
      expect(r.manager.hasCrashed, isFalse);
      await reporter.recordError(StateError('x'), null, category: ErrorCategory.fatalCrash, fatal: true);
      expect(r.manager.hasCrashed, isTrue);
    });

    test('markCrashed before start() is ignored (no session yet)', () {
      final r = Rig();
      r.manager.markCrashed();
      expect(r.manager.hasCrashed, isFalse);
    });
  });

  group('ANR proxy (main isolate stall)', () {
    test('a >= 5 s gap between ticks in foreground marks the session', () async {
      final r = Rig();
      await r.manager.start();
      r.advance(const Duration(seconds: 1));
      r.stallTick!();
      expect(r.manager.hasAnr, isFalse);
      r.advance(const Duration(seconds: 6)); // frozen UI
      r.stallTick!();
      expect(r.manager.hasAnr, isTrue);
      await r.settle();
      expect(r.sent.last.meta['anr'], true);
    });

    test('4.9 s is not a stall', () async {
      final r = Rig();
      await r.manager.start();
      r.advance(const Duration(milliseconds: 4900));
      r.stallTick!();
      expect(r.manager.hasAnr, isFalse);
    });

    test('time spent in background is never reported as a stall', () async {
      final r = Rig();
      await r.manager.start();
      await r.lifecycle(AppLifecycleState.paused);
      r.advance(const Duration(minutes: 10));
      r.stallTick!(); // throttled timer fires late while paused
      expect(r.manager.hasAnr, isFalse);
      await r.lifecycle(AppLifecycleState.resumed);
      r.advance(const Duration(seconds: 1));
      r.stallTick!();
      expect(r.manager.hasAnr, isFalse);
    });

    test('detector alone: reports the stalled duration once per stall', () {
      var now = DateTime.utc(2026);
      final stalls = <Duration>[];
      late void Function() tick;
      final d = MainIsolateStallDetector(
        onStall: stalls.add, now: () => now,
        scheduler: (i, cb) { tick = cb; return () {}; });
      d.start();
      now = now.add(const Duration(seconds: 1)); tick();
      now = now.add(const Duration(seconds: 7)); tick();
      now = now.add(const Duration(seconds: 1)); tick();
      expect(stalls, [const Duration(seconds: 7)]);
      d.stop();
      expect(d.isRunning, isFalse);
    });
  });
}
