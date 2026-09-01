import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/services/network_status_service.dart';

/// A HONEST NOTE ON WHAT THIS FILE DOES AND DOESN'T COVER
/// ─────────────────────────────────────────────────────
/// `NetworkStatusService.isConnected()` tries three checks in order: a
/// DNS lookup, a raw TCP socket connect, then an HTTP HEAD request to the
/// backend. The first two talk to real `dart:io` APIs
/// (`InternetAddress.lookup`, `Socket.connect`) with no dependency-
/// injection seam — mocking them would need wrapping `dart:io` itself
/// behind an interface, which is a bigger change than "add tests" and
/// wasn't made here.
///
/// That means `isConnected()` as a whole is NOT safely unit-testable yet:
/// on a machine with real internet access, the DNS check would likely
/// succeed for real and short-circuit before ever reaching the mocked
/// HTTP client below, making a test pass for the wrong reason. On a
/// machine without internet (e.g. a sandboxed CI runner), the same test
/// would instead be slow (multiple 3-4s timeouts) and still not be
/// testing our logic in isolation.
///
/// What IS safely testable — and what these tests cover — is the one
/// piece of real *business logic* in this file: `backendReachable()`'s
/// handling of the HTTP response, via the `NetworkStatusService.withDio`
/// seam added alongside this test file. The DNS/socket checks remain
/// integration-level concerns; a future pass could introduce a
/// `NetworkProbe` interface (à la [MediaLocalDataSource]) to close that
/// gap the same way `CacheEvictionService` already does it, if that's
/// worth the complexity for this project.
void main() {
  group('NetworkStatusService.backendReachable', () {
    test('a normal 2xx response means reachable', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        return ResponseBody.fromString('{}', 200);
      });
      final service = NetworkStatusService.withDio(dio);

      expect(await service.backendReachable(), isTrue);
    });

    test('a "bad response" (e.g. 404/500) still counts as reachable — '
        'a server replied, so we ARE connected', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        return ResponseBody.fromString('not found', 404);
      });
      final service = NetworkStatusService.withDio(dio);

      expect(await service.backendReachable(), isTrue);
    });

    test(
      'a connection-level failure (no response at all) means unreachable',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _ThrowingAdapter(
          DioExceptionType.connectionError,
        );
        final service = NetworkStatusService.withDio(dio);

        expect(await service.backendReachable(), isFalse);
      },
    );

    test(
      'an unexpected error type is treated as unreachable, never throws',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _ThrowingAdapter(DioExceptionType.unknown);
        final service = NetworkStatusService.withDio(dio);

        expect(await service.backendReachable(), isFalse);
      },
    );
  });
}

/// Minimal fake [HttpClientAdapter] — avoids pulling in a whole HTTP mock
/// package for four test cases.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);
  final ResponseBody Function(RequestOptions options) _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _respond(options);
  }
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this._type);
  final DioExceptionType _type;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, type: _type);
  }
}
