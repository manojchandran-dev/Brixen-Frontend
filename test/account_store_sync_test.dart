import 'package:brixen/core/services/account_store.dart';
import 'package:brixen/core/services/token_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _signIn(String email, String refresh) async {
  await TokenService.clear();
  await TokenService.save(
    token: 'access-$email',
    role: 'company_admin',
    refreshToken: refresh,
    userType: 'company',
    email: email,
  );
  await AccountStore.upsertCurrent();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenService.init();
    await AccountStore.init();
  });

  test(
    'a token change (refresh / PIN unlock) updates the saved account',
    () async {
      await _signIn('a@x.com', 'refresh-1');
      // e.g. PIN unlock rotates the pair: only token + refresh token change.
      await TokenService.save(
        token: 'access-2',
        role: 'company_admin',
        refreshToken: 'refresh-2',
      );
      final saved = AccountStore.find('a@x.com')!;
      expect(saved.refreshToken, 'refresh-2');
      expect(saved.token, 'access-2');
    },
  );

  test('switching keeps each account\'s own latest tokens', () async {
    await _signIn('a@x.com', 'a-1');
    await _signIn('b@x.com', 'b-1');
    await TokenService.save(token: 'b-access', role: 'x', refreshToken: 'b-2');

    // Back to A, rotate A's tokens.
    await AccountStore.find('a@x.com')!.restoreToTokenService();
    await TokenService.save(token: 'a-access', role: 'x', refreshToken: 'a-2');

    expect(AccountStore.find('a@x.com')!.refreshToken, 'a-2');
    expect(AccountStore.find('b@x.com')!.refreshToken, 'b-2');
    expect(AccountStore.accounts, hasLength(2));
  });

  test('a token save never adds an account by itself', () async {
    await TokenService.save(
      token: 't',
      role: 'x',
      refreshToken: 'r',
      email: 'new@x.com',
    );
    expect(AccountStore.find('new@x.com'), isNull);
  });
}
