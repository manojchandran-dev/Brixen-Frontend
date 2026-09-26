import 'package:brixen/core/router/app_router.dart';
import 'package:brixen/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('From a module page, More is not active and tapping it opens More', (tester) async {
    // Module pages pass a tab index they aren't on (Companies used 3 = More).
    Widget page(String name) => Scaffold(
          extendBody: true,
          body: Center(child: Text(name)),
          bottomNavigationBar: const AppBottomNav(activeIndex: 3),
        );
    final router = GoRouter(
      initialLocation: '${AppRouter.dashboard}/companies',
      routes: [
        GoRoute(path: AppRouter.dashboard, builder: (_, _) => page('dashboard'), routes: [
          GoRoute(path: 'companies', builder: (_, _) => page('companies')),
          GoRoute(path: 'more', builder: (_, _) => page('more')),
          GoRoute(path: 'reports', builder: (_, _) => page('reports')),
        ]),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('companies'), findsOneWidget);
    // Nothing highlighted on a module page (filled icons = active).
    expect(find.byIcon(Icons.person_rounded), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('more'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget); // now active
  });
}
