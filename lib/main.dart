import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/account_store.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'core/services/push_token_service.dart';
import 'core/services/token_service.dart';
import 'core/theme/theme_cubit.dart';

void main() async {
  // Start waking the backend now — cold start takes ~20–60s.
  AuthRemoteDatasource.warmUp();
  WidgetsFlutterBinding.ensureInitialized();
  // Swallowed on purpose: fails until google-services.json/
  // GoogleService-Info.plist are added for this project, and push
  // notifications are the only feature that needs it — shouldn't block the
  // rest of the app from starting.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {}
  await TokenService.init();
  await AccountStore.init();
  // After TokenService: a tap that launched the app is reported as opened
  // with the stored auth token.
  if (firebaseReady) {
    try {
      await PushTokenService.init();
    } catch (e) {
      debugPrint('[main] PushTokenService.init failed: $e');
    }
  }
  await themeCubit.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: BrixenApp()));
}
