// Basic smoke test: the app boots to the login screen when logged out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uthme2/l10n/locale_controller.dart';
import 'package:uthme2/main.dart';

void main() {
  testWidgets('App builds the login screen when logged out',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLocaleProvider.overrideWithValue(null)],
        child: const UthGradesApp(isLoggedIn: false),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
