import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_localizations.dart';

/// Secure-storage key holding the user's explicit language override.
/// Absent means "follow the device locale" (with Greek as fallback).
const String localeStorageKey = 'app_locale';

const FlutterSecureStorage _storage = FlutterSecureStorage();

Locale? _supportedLocaleForCode(String code) {
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode == code) return locale;
  }
  return null;
}

/// Reads the stored language override. Returns null when the user has not
/// chosen one (first launch, or "System default" selected).
Future<Locale?> readStoredLocale() async {
  final code = await _storage.read(key: localeStorageKey);
  if (code == null || code.isEmpty) return null;
  return _supportedLocaleForCode(code);
}

/// Resolves the locale to use where there is no [BuildContext] (the
/// home-screen widget runs in a background isolate). Mirrors MaterialApp's
/// resolution: explicit override, else the first supported device locale,
/// else Greek.
Locale resolveLocaleWithoutContext(Locale? override) {
  if (override != null) return override;
  for (final device in WidgetsBinding.instance.platformDispatcher.locales) {
    final match = _supportedLocaleForCode(device.languageCode);
    if (match != null) return match;
  }
  return AppLocalizations.supportedLocales.first;
}

/// Holds the language override the user picked in Settings. `null` means the
/// app follows the device locale. Seeded from [initialLocaleProvider] so the
/// stored value is read once, before the first frame, in `main()`.
final initialLocaleProvider = Provider<Locale?>((ref) {
  throw UnimplementedError('initialLocaleProvider must be overridden');
});

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.read(initialLocaleProvider);

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _storage.delete(key: localeStorageKey);
    } else {
      await _storage.write(key: localeStorageKey, value: locale.languageCode);
    }
  }
}
