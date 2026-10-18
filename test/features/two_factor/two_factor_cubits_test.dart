import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/features/two_factor/cubits/two_factor_challenge_cubit.dart';
import 'package:social_media_app/features/two_factor/cubits/two_factor_challenge_state.dart';
import 'package:social_media_app/features/two_factor/cubits/two_factor_setup_cubit.dart';
import 'package:social_media_app/features/two_factor/cubits/two_factor_setup_state.dart';
import 'package:social_media_app/features/two_factor/models/two_factor_enrollment.dart';
import 'package:social_media_app/features/two_factor/models/two_factor_failure.dart';
import 'package:social_media_app/features/two_factor/services/two_factor_lockout_store.dart';
import 'package:social_media_app/features/two_factor/services/two_factor_service.dart';

class MockService extends Mock implements TwoFactorService {}

const _invalid = TwoFactorFailure(TwoFactorFailureKind.invalidCode, 'bad code');
const _enrollment = TwoFactorEnrollment(
  factorId: 'f1',
  qrSvg: '<svg/>',
  secret: 'ABCD',
  otpauthUri: 'otpauth://totp/x',
);

void main() {
  late MockService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = MockService();
    when(() => service.cancelEnrollment(any())).thenAnswer((_) async {});
  });

  group('TwoFactorSetupCubit', () {
    test('happy path ends on recovery codes', () async {
      when(() => service.beginEnrollment()).thenAnswer((_) async => _enrollment);
      when(() => service.confirmEnrollment('f1', '123456')).thenAnswer((_) async {});
      when(() => service.generateRecoveryCodes())
          .thenAnswer((_) async => ['AAAAA-BBBBB']);

      final cubit = TwoFactorSetupCubit(service);
      await cubit.begin();
      expect(cubit.state.step, TwoFactorSetupStep.scan);
      cubit.goToCodeEntry();
      await cubit.verify('123456');

      expect(cubit.state.step, TwoFactorSetupStep.recoveryCodes);
      expect(cubit.state.codes, ['AAAAA-BBBBB']);
      await cubit.close();
      verifyNever(() => service.cancelEnrollment(any())); // verified: keep it
    });

    test('wrong code stays on entry, counts attempts, shows clock hint', () async {
      when(() => service.beginEnrollment()).thenAnswer((_) async => _enrollment);
      when(() => service.confirmEnrollment(any(), any()))
          .thenAnswer((_) async => throw _invalid);

      final cubit = TwoFactorSetupCubit(service);
      await cubit.begin();
      cubit.goToCodeEntry();
      await cubit.verify('000000');
      expect(cubit.state.showClockHint, isFalse);
      await cubit.verify('000001');

      expect(cubit.state.step, TwoFactorSetupStep.enterCode);
      expect(cubit.state.invalidAttempts, 2);
      expect(cubit.state.showClockHint, isTrue);
      await cubit.close();
    });

    test('abandoning before verification removes the factor', () async {
      when(() => service.beginEnrollment()).thenAnswer((_) async => _enrollment);
      final cubit = TwoFactorSetupCubit(service);
      await cubit.begin();
      await cubit.close();
      verify(() => service.cancelEnrollment('f1')).called(1);
    });

    test('codes failure after verification is recoverable and keeps 2FA', () async {
      when(() => service.beginEnrollment()).thenAnswer((_) async => _enrollment);
      when(() => service.confirmEnrollment(any(), any())).thenAnswer((_) async {});
      var calls = 0;
      when(() => service.generateRecoveryCodes()).thenAnswer((_) async {
        if (calls++ == 0) throw const TwoFactorFailure.unknown();
        return ['CCCCC-DDDDD'];
      });

      final cubit = TwoFactorSetupCubit(service);
      await cubit.begin();
      cubit.goToCodeEntry();
      await cubit.verify('123456');
      expect(cubit.state.step, TwoFactorSetupStep.codesError);
      expect(cubit.state.isActive, isTrue);

      await cubit.retryGenerateCodes();
      expect(cubit.state.step, TwoFactorSetupStep.recoveryCodes);
      await cubit.close();
      verifyNever(() => service.cancelEnrollment(any()));
    });
  });

  group('TwoFactorChallengeCubit', () {
    TwoFactorChallengeCubit make() => TwoFactorChallengeCubit(
      service: service,
      lockout: TwoFactorLockoutStore(),
      userId: 'u1',
    );

    test('valid code completes and resets the lockout', () async {
      when(() => service.verifyLoginCode('123456')).thenAnswer((_) async {});
      final cubit = make();
      await cubit.submitTotp('123456');
      expect(cubit.state.completed, isTrue);
      expect(cubit.state.reenrollRequired, isFalse);
      await cubit.close();
    });

    test('5 wrong codes start a pause that blocks further submits', () async {
      when(() => service.verifyLoginCode(any()))
          .thenAnswer((_) async => throw _invalid);
      final cubit = make();
      for (var i = 0; i < 5; i++) {
        await cubit.submitTotp('00000$i');
      }
      expect(cubit.state.isLocked, isTrue);

      clearInteractions(service);
      await cubit.submitTotp('111111');
      verifyNever(() => service.verifyLoginCode(any()));
      await cubit.close();
    });

    test('a pause survives a new cubit (app restart)', () async {
      when(() => service.verifyLoginCode(any()))
          .thenAnswer((_) async => throw _invalid);
      final first = make();
      for (var i = 0; i < 5; i++) {
        await first.submitTotp('00000$i');
      }
      await first.close();

      final second = make();
      await second.init();
      expect(second.state.isLocked, isTrue);
      await second.close();
    });

    test('backup code success requires re-enrollment', () async {
      when(() => service.redeemBackupCode(any()))
          .thenAnswer((_) async => const RedeemResult(ok: true));
      final cubit = make()..setMode(TwoFactorChallengeMode.backup);
      await cubit.submitBackup('ABCDE-FGHJK');
      expect(cubit.state.completed, isTrue);
      expect(cubit.state.reenrollRequired, isTrue);
      await cubit.close();
    });

    test('backup code locked by the server uses the server countdown', () async {
      when(() => service.redeemBackupCode(any())).thenAnswer(
        (_) async => const RedeemResult(
          ok: false,
          reason: 'locked',
          retryAfterSeconds: 600,
        ),
      );
      final cubit = make()..setMode(TwoFactorChallengeMode.backup);
      await cubit.submitBackup('ABCDE-FGHJK');
      expect(cubit.state.isLocked, isTrue);
      expect(cubit.state.lockRemaining!.inSeconds, greaterThan(590));

      // The backup pause must not block the authenticator field.
      cubit.setMode(TwoFactorChallengeMode.totp);
      expect(cubit.state.isLocked, isFalse);
      await cubit.close();
    });

    test('malformed backup code is rejected locally without a request', () async {
      final cubit = make()..setMode(TwoFactorChallengeMode.backup);
      await cubit.submitBackup('abc');
      expect(cubit.state.error, isNotNull);
      verifyNever(() => service.redeemBackupCode(any()));
      await cubit.close();
    });
  });
}
