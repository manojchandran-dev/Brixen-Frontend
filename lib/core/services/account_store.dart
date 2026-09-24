import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'token_service.dart';

/// A full [TokenService] field snapshot for one previously-signed-in
/// account, keyed by email (the one field every login response always
/// carries — `id` can legitimately come back empty for some roles).
class AccountSnapshot {
  final String email;
  final String token;
  final String role;
  final String? refreshToken;
  final String? userType;
  final String? userId;
  final String? employeeId;
  final String? companyId;
  final String? companyName;
  final String? companyCode;
  final String? ownerName;
  final String? subscriptionPlan;
  final String? onboardingStatus;
  final String? companyStatus;

  const AccountSnapshot({
    required this.email,
    required this.token,
    required this.role,
    this.refreshToken,
    this.userType,
    this.userId,
    this.employeeId,
    this.companyId,
    this.companyName,
    this.companyCode,
    this.ownerName,
    this.subscriptionPlan,
    this.onboardingStatus,
    this.companyStatus,
  });

  factory AccountSnapshot.fromTokenService() => AccountSnapshot(
    email: TokenService.email!,
    token: TokenService.token!,
    role: TokenService.role ?? '',
    refreshToken: TokenService.refreshToken,
    userType: TokenService.userType,
    userId: TokenService.userId,
    employeeId: TokenService.employeeId,
    companyId: TokenService.companyId,
    companyName: TokenService.companyName,
    companyCode: TokenService.companyCode,
    ownerName: TokenService.ownerName,
    subscriptionPlan: TokenService.subscriptionPlan,
    onboardingStatus: TokenService.onboardingStatus,
    companyStatus: TokenService.companyStatus,
  );

  factory AccountSnapshot.fromJson(Map<String, dynamic> j) => AccountSnapshot(
    email: j['email'] as String,
    token: j['token'] as String,
    role: j['role'] as String? ?? '',
    refreshToken: j['refreshToken'] as String?,
    userType: j['userType'] as String?,
    userId: j['userId'] as String?,
    employeeId: j['employeeId'] as String?,
    companyId: j['companyId'] as String?,
    companyName: j['companyName'] as String?,
    companyCode: j['companyCode'] as String?,
    ownerName: j['ownerName'] as String?,
    subscriptionPlan: j['subscriptionPlan'] as String?,
    onboardingStatus: j['onboardingStatus'] as String?,
    companyStatus: j['companyStatus'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'token': token,
    'role': role,
    'refreshToken': refreshToken,
    'userType': userType,
    'userId': userId,
    'employeeId': employeeId,
    'companyId': companyId,
    'companyName': companyName,
    'companyCode': companyCode,
    'ownerName': ownerName,
    'subscriptionPlan': subscriptionPlan,
    'onboardingStatus': onboardingStatus,
    'companyStatus': companyStatus,
  };

  /// Makes this the active session — clears first so a field this snapshot
  /// doesn't carry doesn't leak in from whatever account was active before
  /// ([TokenService.save] merges rather than overwrites).
  Future<void> restoreToTokenService() async {
    await TokenService.clear();
    await TokenService.save(
      token: token,
      role: role,
      refreshToken: refreshToken,
      userType: userType,
      userId: userId,
      employeeId: employeeId,
      email: email,
      companyId: companyId,
      companyName: companyName,
      companyCode: companyCode,
      ownerName: ownerName,
      subscriptionPlan: subscriptionPlan,
      onboardingStatus: onboardingStatus,
      companyStatus: companyStatus,
    );
  }
}

/// The list of accounts signed into on this device, so the "More" tab can
/// offer a Gmail-style switcher instead of a plain single-session logout.
/// Separate from [TokenService], which only ever holds the one *active*
/// session — this is the list of everything switchable.
class AccountStore {
  AccountStore._();

  static List<AccountSnapshot> _accounts = [];
  static List<AccountSnapshot> get accounts => List.unmodifiable(_accounts);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(StorageKeys.savedAccounts) ?? const [];
    _accounts = raw
        .map(
          (s) =>
              AccountSnapshot.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      StorageKeys.savedAccounts,
      _accounts.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  /// Snapshots whatever [TokenService] currently holds into the saved list
  /// (upsert by email). Call right after every successful sign-in/switch so
  /// the switcher always reflects the account that's actually live.
  static Future<void> upsertCurrent() async {
    if (!TokenService.isLoggedIn || TokenService.email == null) return;
    final snap = AccountSnapshot.fromTokenService();
    _accounts.removeWhere((a) => a.email == snap.email);
    _accounts.add(snap);
    await _persist();
  }

  static AccountSnapshot? find(String email) {
    for (final a in _accounts) {
      if (a.email == email) return a;
    }
    return null;
  }

  /// Forgets a saved (non-active) account on this device — does not touch
  /// the backend or the currently active session.
  static Future<void> remove(String email) async {
    _accounts.removeWhere((a) => a.email == email);
    await _persist();
  }
}
