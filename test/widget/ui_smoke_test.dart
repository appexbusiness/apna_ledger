import 'package:apna_ledger/app/app.dart';
import 'package:apna_ledger/app/router/app_router.dart';
import 'package:apna_ledger/core/config/env_config.dart';
import 'package:apna_ledger/core/config/flavor.dart';
import 'package:apna_ledger/core/di/injector.dart';
import 'package:apna_ledger/features/auth/presentation/providers/auth_controller.dart';
import 'package:apna_ledger/features/categories/presentation/category_providers.dart';
import 'package:apna_ledger/features/settings/presentation/app_settings_controller.dart';
import 'package:apna_ledger/features/categories/presentation/categories_screen.dart';
import 'package:apna_ledger/core/theme/app_theme.dart';
import 'package:apna_ledger/features/dashboard/presentation/dashboard_screen.dart';
import 'package:apna_ledger/features/dashboard/presentation/widgets/quick_categories.dart';
import 'package:apna_ledger/features/settings/presentation/settings_screen.dart';
import 'package:apna_ledger/features/transactions/domain/transaction.dart';
import 'package:apna_ledger/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:apna_ledger/features/transactions/presentation/new_txn_args.dart';
import 'package:apna_ledger/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app (theme, router, local backend) and walks every main
/// screen and a few sheets, failing on any build/layout exception.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    EnvConfig.init(
      const EnvConfig(
        flavor: Flavor.qa,
        appName: 'Apna Ledger',
        enableCrashlytics: false,
        enableAnalytics: false,
      ),
    );
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  for (final (dark, scale) in const [(false, 1.0), (true, 1.0), (false, 1.3)]) {
    testWidgets('all screens render (${dark ? 'dark' : 'light'}, text x$scale)',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(appSettingsProvider.notifier)
          .setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      await container.read(appSettingsProvider.notifier).completeOnboarding();
      await container.read(authControllerProvider.notifier).register(
            phone: '9876543210',
            password: 'Secret@123',
            fullName: 'Asha Patel',
          );
      final userId = container.read(authControllerProvider)!.id;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ApnaLedgerApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 4)); // splash → dashboard
      await settle(tester);

      // Guard: tab content must actually lay out (not collapse to 0x0).
      expect(
        tester.getSize(find.byType(DashboardScreen)).height,
        greaterThan(400),
      );

      // Seed a few entries so charts and lists have data.
      final cats = container.read(defaultCategoryIdProvider) ?? 'others';
      final actions = container.read(transactionActionsProvider);
      var n = 0;
      for (final t in TransactionType.values) {
        await actions.save(
          TxnEntry(
            id: 'seed-${n++}',
            userId: userId,
            type: t,
            amount: 1200.0 * n,
            categoryId: cats,
            subCategoryId: null,
            date: DateTime.now().subtract(Duration(days: n)),
            note: 'Seed $n',
            counterparty: t.isLoan ? 'Ravi' : null,
          ),
        );
      }
      await settle(tester);

      final router = container.read(routerProvider);
      const routes = [
        '/dashboard',
        '/dashboard/transactions',
        '/dashboard/categories',
        '/dashboard/settings',
        '/dashboard/recurring',
        '/dashboard/calculator',
        '/dashboard/notes',
        '/dashboard/goals',
        '/dashboard/downloads',
        '/dashboard/settings/how-to',
        '/dashboard/settings/about',
        '/dashboard/settings/privacy',
      ];
      for (final r in routes) {
        router.go(r);
        await settle(tester);
        // Scroll to render lower sections of long screens.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(
            scrollables.first,
            const Offset(0, -1600),
            warnIfMissed: false,
          );
          await settle(tester);
        }
        expect(tester.takeException(), isNull, reason: 'route $r');
      }

      // Add-transaction sheet page (new + prefilled loan type).
      router.go('/dashboard');
      await settle(tester);
      router.push(
        '/dashboard/transaction',
        extra: const NewTxnArgs(type: TransactionType.loanGiven),
      );
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'add transaction');
      router.pop();
      await settle(tester);

      Future<void> openSheet(
        String route,
        Type screen,
        Finder target,
        String what,
      ) async {
        router.go(route);
        await settle(tester);
        final scoped = find.descendant(
          of: find.byType(screen),
          matching: target,
          skipOffstage: false,
        );
        await tester.ensureVisible(scoped.first);
        await settle(tester);
        await tester.tap(scoped.first);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: what);
        Navigator.of(
          tester.element(find.byType(Scaffold).first),
          rootNavigator: true,
        ).maybePop();
        await settle(tester);
      }

      await openSheet(
        '/dashboard/transactions',
        TransactionsScreen,
        find.byIcon(Icons.tune_rounded, skipOffstage: false),
        'filter sheet',
      );
      await openSheet(
        '/dashboard/transactions',
        TransactionsScreen,
        find.textContaining('Seed 1', skipOffstage: false),
        'detail sheet',
      );
      await openSheet(
        '/dashboard/categories',
        CategoriesScreen,
        find.byIcon(Icons.receipt_long_rounded, skipOffstage: false),
        'category sheet',
      );
      await openSheet(
        '/dashboard/settings',
        SettingsScreen,
        find.byIcon(Icons.translate_rounded, skipOffstage: false),
        'language sheet',
      );
      await openSheet(
        '/dashboard/settings',
        SettingsScreen,
        find.byIcon(Icons.pin_rounded, skipOffstage: false),
        'pin sheet',
      );

      // Regression: switching theme while Home is in the background must
      // restyle the Home category tiles too (they used to stay stale).
      router.go('/dashboard/settings');
      await settle(tester);
      await container
          .read(appSettingsProvider.notifier)
          .setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
      await settle(tester);
      router.go('/dashboard');
      await settle(tester);
      final homeCtx = tester.element(find.byType(DashboardScreen));
      final expectCard = Theme.of(homeCtx).brightness == Brightness.dark
          ? AppSurfaces.dark.card
          : AppSurfaces.light.card;
      final tileBoxes = find
          .descendant(
            of: find.byType(QuickCategories, skipOffstage: false),
            matching: find.byType(Container, skipOffstage: false),
            skipOffstage: false,
          )
          .evaluate()
          .map((e) => (e.widget as Container).decoration)
          .whereType<BoxDecoration>()
          // Tile faces are solid card-coloured boxes.
          .map((d) => d.color)
          .where(
            (c) => c == AppSurfaces.light.card || c == AppSurfaces.dark.card,
          );
      expect(tileBoxes, isNotEmpty);
      expect(
        tileBoxes.every((c) => c == expectCard),
        isTrue,
        reason: 'category tiles follow the new theme',
      );
      await container
          .read(appSettingsProvider.notifier)
          .setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      await settle(tester);

      // Floating nav quick-action fan.
      router.go('/dashboard');
      await settle(tester);
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'quick action fan');
    });
  }
}
