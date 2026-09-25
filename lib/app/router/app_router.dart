import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/lock_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/settings/presentation/app_settings_controller.dart';
import '../../features/settings/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/how_to_use_page.dart';
import '../../features/settings/presentation/pages/info_pages.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tools/presentation/calculator_screen.dart';
import '../../features/tools/presentation/goals_screen.dart';
import '../../features/tools/presentation/notes_screen.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/presentation/new_txn_args.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/recurring_screen.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';

/// The app's single source of navigation truth. Redirects are driven by auth
/// state (from [authControllerProvider]) and whether first-run onboarding is
/// complete (from [appSettingsProvider]).
final routerProvider = Provider<GoRouter>((ref) {
  // Bump this listenable whenever auth or onboarding state changes so
  // go_router re-evaluates redirects.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(
    appSettingsProvider.select((s) => s.onboardingDone),
    (_, __) => refresh.value++,
  );

  const authRoutes = {'/login', '/register', '/forgot'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider) != null;
      final onboardingDone = ref.read(appSettingsProvider).onboardingDone;
      final loc = state.matchedLocation;
      final onAuth = authRoutes.contains(loc);

      // Always let the animated splash play; it decides where to go next.
      if (loc == '/splash') return null;

      if (!loggedIn) {
        return onAuth ? null : '/login';
      }
      if (!onboardingDone) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (onAuth || loc == '/onboarding') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
      GoRoute(
          path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Add / edit transaction is pushed above the shell (full-screen).
      // `extra` may be a TxnEntry (edit), NewTxnArgs (new, pre-filled), or null.
      GoRoute(
        path: '/dashboard/transaction',
        builder: (context, state) {
          final extra = state.extra;
          return AddTransactionScreen(
            existing: extra is TxnEntry ? extra : null,
            args: extra is NewTxnArgs ? extra : null,
          );
        },
      ),

      GoRoute(
        path: '/dashboard/transaction/view',
        builder: (context, state) =>
            TransactionDetailScreen(entry: state.extra as TxnEntry),
      ),

      GoRoute(
        path: '/dashboard/calculator',
        builder: (_, __) => const CalculatorScreen(),
      ),

      GoRoute(
        path: '/dashboard/notes',
        builder: (_, __) => const NotesScreen(),
      ),

      GoRoute(
        path: '/dashboard/goals',
        builder: (_, __) => const GoalsScreen(),
      ),

      GoRoute(
        path: '/dashboard/recurring',
        builder: (_, __) => const RecurringScreen(),
      ),

      // Settings sub-pages (full-screen, pushed above the shell).
      GoRoute(
        path: '/dashboard/settings/profile',
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/dashboard/settings/privacy',
        builder: (_, __) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/dashboard/settings/terms',
        builder: (_, __) => const TermsPage(),
      ),
      GoRoute(
        path: '/dashboard/settings/how-to',
        builder: (_, __) => const HowToUsePage(),
      ),
      GoRoute(
        path: '/dashboard/settings/about',
        builder: (_, __) => const AboutPage(),
      ),

      // The signed-in shell with its four bottom-nav branches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DashboardShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard/transactions',
              builder: (_, __) => const TransactionsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard/categories',
              builder: (_, __) => const CategoriesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
