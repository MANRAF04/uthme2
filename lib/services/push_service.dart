import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/locale_controller.dart';
import '../providers/menu_notifications_controller.dart';
import 'api_service.dart';

const String _courseGradedType = 'course_graded';
const String _menuUpcomingType = 'menu_upcoming';

/// FCM registration and incoming "a course was graded" pushes.
///
/// The device is addressed by its Firebase Installation ID (FID), delivered
/// through [FirebaseMessaging.onRegistered] after [FirebaseMessaging.register].
///
/// Firebase is optional: a build without google-services.json (forks, CI)
/// leaves [_available] false and every call here becomes a no-op.
class PushService {
  static const _storage = FlutterSecureStorage();
  static final _api = ApiService();
  static final _courseGraded = StreamController<void>.broadcast();
  static final _menuOpened = StreamController<void>.broadcast();

  static bool _available = false;
  static bool _pushEnabled = false;
  static bool _registeredThisSession = false;
  static String? _currentFid;
  static String? _postedFid;

  /// Fires when a course_graded push arrives in the foreground or is tapped.
  static Stream<void> get onCourseGraded => _courseGraded.stream;

  /// Fires when the user taps a menu_upcoming push.
  static Stream<void> get onMenuOpened => _menuOpened.stream;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (error) {
      debugPrint('[Push] Firebase unavailable, push disabled: $error');
      return;
    }

    // Subscribed before any register() call so the FID event is never missed.
    FirebaseMessaging.instance.onRegistered.listen(_onRegistered);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  /// Handles a push that cold-started the app. Call once the UI is listening.
  static Future<void> handleLaunchMessage() async {
    if (!_available) return;

    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handleOpenedMessage(message);
  }

  /// Registers this device once per app session. The server only knows the
  /// user after their first successful sync, so call this after one.
  static Future<void> ensureRegistered() async {
    if (!_available || _registeredThisSession) return;
    _registeredThisSession = true;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      _pushEnabled = true;
      await FirebaseMessaging.instance.register();

      final fid = _currentFid;
      if (fid != null) await _postFid(fid);
    } catch (error) {
      _registeredThisSession = false;
      debugPrint('[Push] Device registration failed: $error');
    }
  }

  /// Sends the current locale to the server so pushes use the right language.
  static Future<void> refreshRegistration() async {
    _registeredThisSession = false;
    _postedFid = null;
    await ensureRegistered();
  }

  /// Detaches this device from the account. Call before clearing credentials.
  /// Never throws, so a network failure cannot block logout.
  static Future<void> unregister({
    required String username,
    required String password,
  }) async {
    if (!_available) return;

    _pushEnabled = false;
    _registeredThisSession = false;
    _postedFid = null;

    final fid = _currentFid;
    if (fid != null) {
      try {
        await _api.unregisterDevice(
          username: username,
          password: password,
          fcmToken: fid,
        );
      } catch (error) {
        debugPrint('[Push] Device unregistration failed: $error');
      }
    }

    // Unregistering with FCM guarantees the old account stops receiving pushes
    // on this phone even if the server call above failed.
    try {
      await FirebaseMessaging.instance.unregister();
      _currentFid = null;
    } catch (error) {
      debugPrint('[Push] FCM unregistration failed: $error');
    }
  }

  static Future<void> _onRegistered(String fid) async {
    _currentFid = fid;
    if (!_pushEnabled) return;

    try {
      await _postFid(fid);
    } catch (error) {
      debugPrint('[Push] Device registration failed: $error');
    }
  }

  static Future<void> _postFid(String fid) async {
    if (fid == _postedFid) return;

    final username = (await _storage.read(key: 'username'))?.trim();
    final password = await _storage.read(key: 'password');
    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      return;
    }

    final locale = resolveLocaleWithoutContext(await readStoredLocale());

    final menuNotificationsEnabled = await _api.registerDevice(
      username: username,
      password: password,
      fcmToken: fid,
      platform: defaultTargetPlatform.name,
      locale: locale.languageCode,
    );
    _postedFid = fid;
    await writeStoredMenuNotifications(menuNotificationsEnabled);
  }

  /// The OS shows nothing while the app is open, so a new grade just refreshes
  /// the list. A menu push needs no action, the user is already in the app.
  static void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == _courseGradedType) {
      _courseGraded.add(null);
    }
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    switch (message.data['type']) {
      case _courseGradedType:
        _courseGraded.add(null);
      case _menuUpcomingType:
        _menuOpened.add(null);
    }
  }
}
