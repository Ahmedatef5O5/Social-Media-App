# Contributing to Social Media App

## Before Your First Push

```powershell
flutter pub get
.\scripts\local_ci.ps1
If this passes, CI will pass. If it fails, CI will fail.

Running the Application
Secrets are injected at compile time via --dart-define-from-file, never via a Git-tracked file:

PowerShell
flutter run --dart-define-from-file=.env
Without it, AppSecrets.assertSecretsLoaded() triggers an assertion with an explicit diagnostic message.

The Four Rules Enforced in Code Review
1. No catch Block Ends at debugPrint
debugPrint is a no-op in production. Every new catch block must route through structured observability:

Dart
obs.recordError(e, s, feature: 'chat', operation: 'sendMessage');
// or
_log.error(e, s, operation: 'sendMessage');
If the error is genuinely expected (e.g., user cancellation), pass category: ErrorCategory.businessExpected—explicit declaration is mandatory; silent failure is not an option.

2. Every .select() Query Must Be Bounded
Current baseline: 101 .select() calls versus 15 .range()/.limit() calls. Do not increase the first number. If a query is intrinsically bounded (e.g., .eq('id', x).maybeSingle()), document that explicitly with an inline comment.

3. Every Subscription Is Cancelled, Every Channel Is Tracked
Dart
_sub = stream.listen(...);
RealtimeDiagnostics.instance.onChannelCreated(topic, ownerUserId: currentUserId);

@override
Future<void> close() {
  _sub?.cancel();
  RealtimeDiagnostics.instance.onChannelClosed(topic);
  return super.close();
}
analysis_options.yaml promotes cancel_subscriptions and close_sinks to error severity, so CI catches most leaks—but not all of them.

4. No New Singletons in Testable Code Paths
If you need a service inside a Cubit, inject it via the constructor with a default fallback:

Dart
MyCubit({NetworkStatusService? networkStatus})
  : _networkStatus = networkStatus ?? NetworkStatusService.instance;
Branch and Commit Naming
Plaintext
feat/…    New feature
fix/…     Bug fix
test/…    Tests only
chore/…   Infrastructure, CI, documentation
Fixing a Production Bug
The sequence is non-negotiable:

Inspect the Crashlytics issue—review custom keys and breadcrumbs.

Write a failing test. Do not touch production code before seeing it fail (red).

Implement the fix.

Attach the Crashlytics issue link and the test file path in the PR description.

A test written after the fix only proves that the code does what it currently does—not that the bug is gone.
