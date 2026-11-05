import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'grades_provider.dart';

/// Secure-storage key mirroring the server's menu_notifications_enabled flag.
/// Absent means the default: enabled.
const String menuNotificationsStorageKey = 'menu_notifications_enabled';

const FlutterSecureStorage _storage = FlutterSecureStorage();

Future<bool> readStoredMenuNotifications() async {
  final value = await _storage.read(key: menuNotificationsStorageKey);
  return value != 'false';
}

Future<void> writeStoredMenuNotifications(bool enabled) {
  return _storage.write(
    key: menuNotificationsStorageKey,
    value: enabled ? 'true' : 'false',
  );
}

/// Seeded in `main()` so the stored value is read once, before the first frame.
final initialMenuNotificationsProvider = Provider<bool>((ref) {
  throw UnimplementedError('initialMenuNotificationsProvider must be overridden');
});

/// Whether the pre-meal push for the preferred restaurant is on.
final menuNotificationsProvider =
    NotifierProvider<MenuNotificationsController, bool>(MenuNotificationsController.new);

class MenuNotificationsController extends Notifier<bool> {
  @override
  bool build() => ref.read(initialMenuNotificationsProvider);

  /// Optimistically flips the switch, then syncs to the server. Reverts and
  /// rethrows when the server call fails, so the UI never shows a state the
  /// server does not have.
  Future<void> setEnabled(bool enabled) async {
    final previous = state;
    state = enabled;

    try {
      final username = (await _storage.read(key: 'username'))?.trim();
      final password = await _storage.read(key: 'password');
      if (username == null || username.isEmpty || password == null || password.isEmpty) {
        throw Exception('Missing credentials');
      }

      await ref.read(apiProvider).setMenuNotifications(
            username: username,
            password: password,
            enabled: enabled,
          );
      await writeStoredMenuNotifications(enabled);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}
