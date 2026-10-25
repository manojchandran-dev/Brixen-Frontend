// End-to-end account switching against a fake auth server that behaves
// like the real one: access tokens expire, refresh tokens are single-use
// (each refresh revokes the one it used).
//
// Needs the API base URL pointed at the fake server:
//   flutter test test/account_switch_flow_test.dart \
//     --dart-define=API_BASE_URL=http://127.0.0.1:38123
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:brixen/core/config/app_config.dart';
import 'package:brixen/core/network/token_refresh_interceptor.dart';
import 'package:brixen/core/services/account_store.dart';
import 'package:brixen/core/services/token_service.dart';
import 'package:brixen/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _port = 38123;

class FakeAuthServer {
  late HttpServer _server;
  final validAccess = <String, String>{}; // access token → email
  final liveRefresh = <String, String>{}; // refresh token → email
  int refreshCalls = 0;
  Duration refreshDelay = Duration.zero;
  int _n = 0;

  ({String access, String refresh}) issue(String email) {
    _n++;
    final access = 'acc-$email-$_n';
    final refresh = 'ref-$email-$_n';
    validAccess[access] = email;
    liveRefresh[refresh] = email;
    return (access: access, refresh: refresh);
  }

  void expireAccess(String email) =>
      validAccess.removeWhere((_, e) => e == email);

  void revokeRefresh(String email) =>
      liveRefresh.removeWhere((_, e) => e == email);

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
    _server.listen((req) async {
      final res = req.response..headers.contentType = ContentType.json;
      final bearer = (req.headers.value('authorization') ?? '').replaceFirst(
        'Bearer ',
        '',
      );
      if (req.uri.path == '/api/v1/auth/refresh') {
        refreshCalls++;
        final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
        await Future<void>.delayed(refreshDelay);
        final email = liveRefresh.remove(body['refreshToken']);
        if (email == null) {
          res.statusCode = 401;
          res.write(
            jsonEncode({'message': 'Invalid or expired refresh token'}),
          );
        } else {
          final t = issue(email);
          res.write(
            jsonEncode({
              'data': {'accessToken': t.access, 'refreshToken': t.refresh},
            }),
          );
        }
      } else {
        // /auth/me and any other API route: a valid access token, or 401.
        final email = validAccess[bearer];
        res.statusCode = email == null ? 401 : 200;
        res.write(
          jsonEncode({
            'data': {'email': email},
          }),
        );
      }
      await res.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

late FakeAuthServer server;

/// Signs [email] in on the device (as AuthCubit.signIn would).
Future<void> signIn(String email) async {
  final t = server.issue(email);
  await TokenService.clear();
  await TokenService.save(
    token: t.access,
    role: 'company_admin',
    refreshToken: t.refresh,
    userType: 'company',
    email: email,
  );
  await AccountStore.upsertCurrent();
}

void main() {
  // Only meaningful with the API pointed at the fake server; skipped in a
  // plain `flutter test` run.
  if (AppConfig.baseUrl != 'http://127.0.0.1:$_port') {
    test(
      'account switching flow',
      () {},
      skip: 'run with --dart-define=API_BASE_URL=http://127.0.0.1:$_port',
    );
    return;
  }

  setUpAll(() async {
    server = FakeAuthServer();
    await server.start();
  });
  tearDownAll(() => server.stop());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenService.init();
    await AccountStore.init();
    server
      ..validAccess.clear()
      ..liveRefresh.clear()
      ..refreshCalls = 0
      ..refreshDelay = Duration.zero;
  });

  test(
    'switching to an account whose access token expired renews it',
    () async {
      await signIn('b@x.com');
      await signIn('a@x.com'); // A active, B saved
      server.expireAccess('b@x.com');

      expect(await authCubit.switchAccount('b@x.com'), SwitchResult.switched);
      expect(TokenService.email, 'b@x.com');
      // B's saved copy holds the NEW pair, which the server accepts.
      final b = AccountStore.find('b@x.com')!;
      expect(server.validAccess[b.token], 'b@x.com');
      expect(server.liveRefresh[b.refreshToken], 'b@x.com');
      // A untouched and still live.
      expect(
        server.liveRefresh[AccountStore.find('a@x.com')!.refreshToken],
        'a@x.com',
      );
    },
  );

  test('switching back and forth many times never logs out', () async {
    await signIn('b@x.com');
    await signIn('a@x.com');
    for (var i = 0; i < 6; i++) {
      final to = i.isEven ? 'b@x.com' : 'a@x.com';
      server.expireAccess(to); // always stale when switched to
      expect(
        await authCubit.switchAccount(to),
        SwitchResult.switched,
        reason: 'switch #$i to $to',
      );
      expect(TokenService.email, to);
    }
    expect(AccountStore.accounts, hasLength(2));
  });

  test(
    'an account that is really signed out is removed; the current one stays',
    () async {
      await signIn('b@x.com');
      await signIn('a@x.com');
      server
        ..expireAccess('b@x.com')
        ..revokeRefresh('b@x.com');

      expect(await authCubit.switchAccount('b@x.com'), SwitchResult.expired);
      expect(TokenService.email, 'a@x.com');
      expect(server.validAccess[TokenService.token], 'a@x.com');
      expect(AccountStore.find('b@x.com'), isNull);
      expect(AccountStore.find('a@x.com'), isNotNull);
    },
  );

  test(
    'a refresh that finishes after switching away goes to its own account',
    () async {
      await signIn('b@x.com');
      await signIn('a@x.com');
      server.refreshDelay = const Duration(milliseconds: 300);

      final refreshing = TokenRefreshInterceptor.refreshNow(); // for A
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await AccountStore.find('b@x.com')!.restoreToTokenService(); // B now

      expect(await refreshing, isFalse);
      expect(TokenService.email, 'b@x.com', reason: 'B stays active');
      expect(server.validAccess[TokenService.token], 'b@x.com');
      // A's saved copy got A's new pair, which the server accepts.
      final a = AccountStore.find('a@x.com')!;
      expect(server.liveRefresh[a.refreshToken], 'a@x.com');
      expect(server.validAccess[a.token], 'a@x.com');
    },
  );

  test(
    'a request still carrying the old account\'s token is replayed, not refreshed',
    () async {
      await signIn('b@x.com');
      await signIn('a@x.com');
      final oldToken = TokenService.token!;
      await AccountStore.find('b@x.com')!.restoreToTokenService(); // switched
      server.expireAccess('a@x.com'); // the in-flight request now gets 401

      final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))
        ..interceptors.add(TokenRefreshInterceptor());
      final resp = await dio.get(
        '/api/v1/ping',
        options: Options(headers: {'Authorization': 'Bearer $oldToken'}),
      );
      expect(resp.statusCode, 200);
      expect(server.refreshCalls, 0, reason: 'no refresh token spent');
      expect(server.liveRefresh[TokenService.refreshToken], 'b@x.com');
    },
  );
}
