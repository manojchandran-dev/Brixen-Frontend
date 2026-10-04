import 'package:brixen/core/router/app_router.dart';
import 'package:brixen/features/chat/domain/entities/chat_conversation.dart';
import 'package:brixen/features/chat/presentation/providers/chat_provider.dart';
import 'package:brixen/features/navigation/domain/entities/nav_module.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// No network in tests: an empty conversation.
class _NoMessages extends ChatMessagesNotifier {
  @override
  Future<List<ChatMessage>> build(String companyId) async => const [];
}

void main() {
  testWidgets(
    'From a module page, More is not active and tapping it opens More',
    (tester) async {
      // Module pages pass a tab index they aren't on (Companies used 3 = More).
      Widget page(String name) => Scaffold(
        extendBody: true,
        body: Center(child: Text(name)),
        bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      );
      final router = GoRouter(
        initialLocation: '${AppRouter.dashboard}/companies',
        routes: [
          GoRoute(
            path: AppRouter.dashboard,
            builder: (_, _) => page('dashboard'),
            routes: [
              GoRoute(path: 'companies', builder: (_, _) => page('companies')),
              GoRoute(path: 'more', builder: (_, _) => page('more')),
              GoRoute(path: 'reports', builder: (_, _) => page('reports')),
              GoRoute(path: 'chat', builder: (_, _) => page('chat')),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith(_NoMessages.new),
            moduleAccessProvider.overrideWith(
              (ref, _) => const ModuleAccess(
                view: true,
                create: true,
                edit: true,
                delete: true,
              ),
            ),
            navModulesProvider.overrideWith(
              (ref) async => const [NavModule(id: 'c', name: 'Chat')],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('companies'), findsOneWidget);
      // Nothing highlighted on a module page (filled icons = active).
      expect(find.byIcon(Icons.person_rounded), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('more'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget); // now active

      // Chat button (company user): opens the chat as a sheet over the
      // page — no navigation.
      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Brixen Support'), findsOneWidget);
      expect(find.text('more'), findsOneWidget); // still on More

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets('Dashboard ↔ Report: the highlight follows the page', (
    tester,
  ) async {
    Widget page(String name) => Scaffold(
      extendBody: true,
      body: Center(child: Text(name)),
      bottomNavigationBar: const AppBottomNav(activeIndex: 0),
    );
    final router = GoRouter(
      initialLocation: AppRouter.dashboard,
      routes: [
        GoRoute(
          path: AppRouter.dashboard,
          builder: (_, _) => page('dashboard'),
          routes: [
            GoRoute(path: 'reports', builder: (_, _) => page('reports')),
            GoRoute(path: 'more', builder: (_, _) => page('more')),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [navModulesProvider.overrideWith((ref) async => const [])],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget); // active

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('reports'), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dashboard_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsNothing);
  });
}
