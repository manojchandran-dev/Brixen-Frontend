import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

class BrixenApp extends StatefulWidget {
  const BrixenApp({super.key});

  @override
  State<BrixenApp> createState() => _BrixenAppState();
}

class _BrixenAppState extends State<BrixenApp> {
  late final StreamSubscription<ThemeMode> _themeSub;

  @override
  void initState() {
    super.initState();
    _themeSub = themeCubit.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _themeSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppColors' surface/text tokens are runtime getters, not consts, so
    // they need this set before anything below reads them this frame.
    AppColors.setBrightness(themeCubit.isDark ? Brightness.dark : Brightness.light);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeCubit.isDark ? Brightness.light : Brightness.dark,
      ),
    );
    return MaterialApp.router(
      title: 'Brixen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCubit.state,
      routerConfig: AppRouter.router,
    );
  }
}
