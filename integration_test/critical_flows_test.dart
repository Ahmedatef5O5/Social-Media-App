import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// LAYER 4 — integration tests.
///
/// READ THIS BEFORE ADDING TESTS HERE
/// ──────────────────────────────────
/// The V6 audit asked for an end-to-end flow:
///
///   Login → Home → Feed → Open Post → Chat → Send → Switch Account
///
/// Written naively, that test needs a real Supabase project, two real
/// accounts, real credentials on the runner, and a live Realtime
/// connection. It would be slow, it would be flaky, it would fail for
/// network reasons more often than for code reasons, and within two months
/// somebody would add `--exclude-tags e2e` to CI and it would be dead.
///
/// So this file is deliberately a SKELETON with one honest smoke test, plus
/// the exact preconditions the real flows need. Do not fill it in until
/// those preconditions exist:
///
///   1. A dedicated `staging` Supabase project, separate from production.
///   2. Two seeded test accounts whose data can be reset between runs
///      (an RPC like `reset_e2e_account(uuid)` — see docs/testing.md).
///   3. Credentials for them as GitHub Secrets, fed through
///      `--dart-define-from-file`.
///   4. A device/emulator job. These do NOT run in the normal CI pipeline:
///      they belong on a nightly schedule, because an emulator boot alone
///      costs more than the entire unit suite.
///
/// Until then, the account-isolation behaviour (V6 C-02) is covered at the
/// cubit level in `test/features/single_chats/cubits/chat_details_cubit_test.dart`
/// and at the realtime level in
/// `test/core/observability/realtime_diagnostics_test.dart`. Those run in
/// seconds, on every PR, with no credentials — which makes them worth more
/// than a fragile e2e test that runs nightly and is muted by March.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('smoke', () {
    testWidgets('the integration harness itself boots', (tester) async {
      // Intentionally does not call `app.main()`. Doing so would run
      // `initializeCriticalBeforeRunApp()`, which now initialises Firebase
      // and therefore needs google-services.json on the device.
      //
      // Once a staging environment exists, replace this with:
      //   app.main();
      //   await tester.pumpAndSettle();
      expect(true, isTrue);
    });
  });

  // TODO(e2e): enable once preconditions 1–4 above are met.
  //
  // group('account isolation — V6 C-02', () {
  //   testWidgets('signing into account B shows none of account A\'s chats',
  //       (tester) async {
  //     await signIn(tester, accountA);
  //     await openChat(tester, withPeer: peerOfA);
  //     await sendMessage(tester, 'marker-a');
  //     await signOut(tester);
  //     await signIn(tester, accountB);
  //     expect(find.text('marker-a'), findsNothing);
  //   });
  // });
}
