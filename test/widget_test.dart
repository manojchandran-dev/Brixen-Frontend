import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brixen/core/theme/app_colors.dart';
import 'package:brixen/core/theme/app_theme.dart';
import 'package:brixen/core/theme/theme_cubit.dart';
import 'package:brixen/features/auth/presentation/pages/sign_in_page.dart';
import 'package:brixen/features/auth/presentation/pages/sign_up_page.dart';
import 'package:brixen/shared/widgets/brixen_button.dart';
import 'package:brixen/shared/widgets/brixen_text_field.dart';

// Top-level helper — accessible in every group
Widget themed(Widget child, {ThemeMode mode = ThemeMode.dark}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    home: child,
  );
}

void main() {
  // ── AppColors ────────────────────────────────────────────────────

  group('AppColors', () {
    test('dark background is near-black', () {
      expect(AppColors.background, const Color(0xFF0C0C0C));
    });

    test('light background is near-white silver', () {
      expect(AppColors.lightBackground, const Color(0xFFF0F0F0));
    });

    test('silver gradient has 4 stops', () {
      expect(AppColors.silverGradient.colors.length, 4);
    });
  });

  // ── ThemeCubit ───────────────────────────────────────────────────

  group('ThemeCubit', () {
    late ThemeCubit cubit;

    setUp(() => cubit = ThemeCubit());
    tearDown(() => cubit.close());

    test('initial state is dark', () {
      expect(cubit.state, ThemeMode.dark);
      expect(cubit.isDark, true);
    });

    test('toggle switches to light', () {
      cubit.toggle();
      expect(cubit.state, ThemeMode.light);
      expect(cubit.isDark, false);
    });

    test('double toggle returns to dark', () {
      cubit.toggle();
      cubit.toggle();
      expect(cubit.state, ThemeMode.dark);
    });

    test('setMode works for any ThemeMode', () {
      cubit.setMode(ThemeMode.system);
      expect(cubit.state, ThemeMode.system);
    });
  });

  // ── AppTheme ─────────────────────────────────────────────────────

  group('AppTheme', () {
    test('dark theme scaffold background', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.background);
    });

    test('light theme scaffold background', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.lightBackground);
    });

    test('dark primary color is silver', () {
      expect(AppTheme.dark.colorScheme.primary, AppColors.silver);
    });

    test('light primary color is near-black', () {
      expect(AppTheme.light.colorScheme.primary, const Color(0xFF111111));
    });
  });

  // ── BrixenButton ─────────────────────────────────────────────────

  group('BrixenButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        themed(Scaffold(body: BrixenButton(label: 'Sign In', onPressed: () {}))),
      );
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading', (tester) async {
      await tester.pumpWidget(
        themed(Scaffold(
          body: BrixenButton(label: 'Sign In', isLoading: true, onPressed: () {}),
        )),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('outlined variant renders label', (tester) async {
      await tester.pumpWidget(
        themed(Scaffold(
          body: BrixenButton(label: 'Cancel', isOutlined: true, onPressed: () {}),
        )),
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('fires onPressed on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        themed(Scaffold(
          body: BrixenButton(label: 'Go', onPressed: () => tapped = true),
        )),
      );
      await tester.tap(find.text('Go'));
      expect(tapped, true);
    });
  });

  // ── BrixenTextField ──────────────────────────────────────────────

  group('BrixenTextField', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        themed(Scaffold(body: BrixenTextField(label: 'Email'))),
      );
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('password field shows visibility icon', (tester) async {
      await tester.pumpWidget(
        themed(Scaffold(body: BrixenTextField(label: 'Password', isPassword: true))),
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('visibility icon toggles on tap', (tester) async {
      await tester.pumpWidget(
        themed(Scaffold(body: BrixenTextField(label: 'Password', isPassword: true))),
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  // ── SignInPage ───────────────────────────────────────────────────

  group('SignInPage', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(themed(const SignInPage()));
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('empty submit shows email required error', (tester) async {
      await tester.pumpWidget(themed(const SignInPage()));
      await tester.pump();
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('invalid email shows format error', (tester) async {
      await tester.pumpWidget(themed(const SignInPage()));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });
  });

  // ── SignUpPage ───────────────────────────────────────────────────

  group('SignUpPage', () {
    testWidgets('renders all 5 fields', (tester) async {
      await tester.pumpWidget(themed(const SignUpPage()));
      await tester.pump();
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Company Code'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('password mismatch shows error', (tester) async {
      await tester.pumpWidget(themed(const SignUpPage()));
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'ACME2024');
      await tester.enterText(fields.at(2), 'john@acme.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'differentpass');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
