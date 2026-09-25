import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apna_ledger/core/di/injector.dart';
import 'package:apna_ledger/core/widgets/app_button.dart';
import 'package:apna_ledger/features/auth/presentation/screens/login_screen.dart';
import 'package:apna_ledger/l10n/app_localizations.dart';

void main() {
  testWidgets('LoginScreen renders phone, password and a submit button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Two text fields (phone + password) and the primary button are present.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(AppButton), findsOneWidget);
  });
}
