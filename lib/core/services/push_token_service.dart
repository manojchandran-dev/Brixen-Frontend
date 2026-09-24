import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart' show mapDioError, CompanyScopeInterceptor;
import '../network/api_endpoints.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import 'token_service.dart';

final _dio =
    Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        ),
      )
      ..interceptors.add(_AuthInterceptor())
      ..interceptors.add(CompanyScopeInterceptor())
      ..interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenService.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Registers/unregisters this device's FCM token with the backend
/// (`POST`/`DELETE /api/v1/notifications/push/devices`) so pushes composed
/// in the admin's Push Notifications screen actually reach this device.
///
/// Every call is best-effort — permission denial, no network, or Firebase
/// not configured should never block or interrupt sign-in/sign-out — but
/// failures are logged via [debugPrint] rather than swallowed silently, so
/// a broken registration actually shows up in the run console instead of
/// just quietly not working.
class PushTokenService {
  PushTokenService._();

  static String get _platform {
    if (kIsWeb) return 'web';
    return Platform.isIOS ? 'ios' : 'android';
  }

  static final _local = FlutterLocalNotificationsPlugin();
  // The backend picks the channel per message from the notification's
  // priority (fcm.js): important/urgent -> heads-up, normal -> quiet.
  // Ids must stay in sync with it.
  static const _highChannel = AndroidNotificationChannel(
    'brixen_push',
    'Important notifications',
    importance: Importance.high,
  );
  static const _normalChannel = AndroidNotificationChannel(
    'brixen_push_normal',
    'Notifications',
    importance: Importance.defaultImportance,
  );

  /// Route of a notification tapped while the app was closed. It can't be
  /// opened yet (splash → lock/PIN comes first), so the lock/PIN screens
  /// take it in place of going straight to the dashboard.
  static String? _pendingRoute;
  static String? takePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }

  /// `open_on_tap` (sent by the backend in the push's data) → app route.
  /// Targets with no page of their own yet land on the dashboard.
  static String? _routeFor(Map<String, dynamic> data) {
    final specific = data['specific_page_route'] as String? ?? '';
    return switch (data['open_on_tap']) {
      null || 'none' => null,
      'support' => RouteNames.support,
      'specificPage' when specific.startsWith('/') => specific,
      _ => RouteNames.dashboard,
    };
  }

  /// A push was tapped: count it as opened, then open its target.
  static void _onTap(Map<String, dynamic> data, {bool coldStart = false}) {
    final id = data['notification_id'];
    if (id != null) {
      _dio
          .post('${ApiEndpoints.pushNotifications}/$id/opened')
          .catchError((Object e) {
        debugPrint('[PushTokenService] markOpened failed: $e');
        return Response(requestOptions: RequestOptions());
      });
    }
    final route = _routeFor(data);
    if (route == null) return;
    if (coldStart) {
      _pendingRoute = route;
    } else {
      AppRouter.router.push(route);
    }
  }

  /// Call once at startup, after [TokenService.init] (tap tracking needs
  /// the auth token). Handles taps, and showing pushes while the app is open.
  static Future<void> init() async {
    if (kIsWeb) return;

    // Taps on FCM's own (background) notifications.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _onTap(m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onTap(initial.data, coldStart: true);

    // FCM only shows the system notification when the app is in the
    // background — while it's open the message arrives silently via
    // [FirebaseMessaging.onMessage]. iOS can display it itself:
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!Platform.isAndroid) return;

    // Android: nothing is shown in the foreground, so post a local one
    // carrying the push's data as payload, so tapping it works the same.
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) _onTap(jsonDecode(r.payload!));
      },
    );
    final launch = await _local.getNotificationAppLaunchDetails();
    final launchPayload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && launchPayload != null) {
      _onTap(jsonDecode(launchPayload), coldStart: true);
    }
    final android = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_highChannel);
    await android?.createNotificationChannel(_normalChannel);

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      final high = n.android?.channelId != _normalChannel.id;
      final channel = high ? _highChannel : _normalChannel;
      _local.show(
        id: message.hashCode,
        title: n.title,
        body: n.body,
        payload: jsonEncode(message.data),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            importance: channel.importance,
            priority: high ? Priority.high : Priority.defaultPriority,
          ),
        ),
      );
    });
  }

  /// Call after every successful sign-in, account switch, and auto-login.
  static Future<void> register() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      debugPrint('[PushTokenService] permission: ${settings.authorizationStatus}');
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('[PushTokenService] getToken() returned null — cannot register');
        return;
      }
      await _dio.post(ApiEndpoints.pushDevices, data: {'token': token, 'platform': _platform});
      debugPrint('[PushTokenService] registered device token');
    } catch (e) {
      debugPrint('[PushTokenService] register() failed: ${e is DioException ? mapDioError(e) : e}');
    }
  }

  /// Call before sign-out clears the auth token (the request still needs it).
  static Future<void> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _dio.delete(ApiEndpoints.pushDevices, data: {'token': token});
      debugPrint('[PushTokenService] unregistered device token');
    } catch (e) {
      debugPrint('[PushTokenService] unregister() failed: ${e is DioException ? mapDioError(e) : e}');
    }
  }
}
