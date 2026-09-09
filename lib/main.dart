import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'providers/average_mode_controller.dart';
import 'screens/login_screen.dart';
import 'screens/grades_screen.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine is ready before we read from storage
  WidgetsFlutterBinding.ensureInitialized();

  // Load locale-aware date symbols (weekday/month names) for all locales.
  await initializeDateFormatting();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
  }

  const storage = FlutterSecureStorage();
  final username = (await storage.read(key: 'username'))?.trim();
  final password = await storage.read(key: 'password');
  final isLoggedIn =
      username != null && username.isNotEmpty && password != null && password.isNotEmpty;
  final initialLocale = await readStoredLocale();
  final initialWeightedMode = await readStoredWeightedMode();

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(initialLocale),
        initialWeightedModeProvider.overrideWithValue(initialWeightedMode),
      ],
      child: UthGradesApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class UthGradesApp extends ConsumerWidget {
  final bool isLoggedIn;

  const UthGradesApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // null = follow the device locale (Greek fallback via supportedLocales).
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Automatically route based on storage
      home: isLoggedIn ? const GradesScreen() : const LoginScreen(),
    );
  }
}