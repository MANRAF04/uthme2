import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../providers/menu_notifications_controller.dart';
import '../services/cache_service.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped.dart';
import '../widgets/large_title_bar.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _storage = FlutterSecureStorage();

  String? _username;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = (await _storage.read(key: 'username'))?.trim();
    if (mounted) setState(() => _username = username);
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _showConfirm(
      title: l10n.logOutConfirmTitle,
      message: l10n.logOutConfirmMessage,
      confirmLabel: l10n.logOut,
      cancelLabel: l10n.cancel,
    );
    if (confirmed == true) await _logout();
  }

  Future<bool?> _showConfirm({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    }

    final p = context.palette;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppText.headline.copyWith(color: p.label)),
        content: Text(
          message,
          style: AppText.subheadline.copyWith(color: p.secondaryLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel, style: TextStyle(color: p.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Credentials go first so nothing still mounted can start a new fetch with
  /// them; the signed-in shell is then replaced by the login screen.
  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    setState(() => _loggingOut = true);

    final username = (await _storage.read(key: 'username'))?.trim();
    final password = await _storage.read(key: 'password');

    if (username != null && username.isNotEmpty) {
      if (password != null && password.isNotEmpty) {
        await PushService.unregister(username: username, password: password);
      }
      await CacheService.clearGrades(username);
    }
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final current = ref.watch(localeProvider);

    final languages = <(String, Locale?)>[
      (l10n.systemDefault, null),
      ('English', const Locale('en')),
      ('Ελληνικά', const Locale('el')),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleBar(title: l10n.settings),
          SliverList.list(
            children: [
              const SizedBox(height: 8),
              GroupedSection(
                header: l10n.account,
                separatorInset: 16,
                children: [
                  GroupedRow(
                    leading: IconTile(
                      icon: CupertinoIcons.person_fill,
                      color: p.accent,
                      size: 40,
                    ),
                    title: _username ?? '',
                    subtitle: l10n.usernameLabel,
                  ),
                  GroupedRow(
                    title: l10n.logOut,
                    titleColor: p.danger,
                    centerTitle: true,
                    trailing: _loggingOut
                        ? const CupertinoActivityIndicator()
                        : null,
                    onTap: _loggingOut ? null : _confirmLogout,
                  ),
                ],
              ),
              GroupedSection(
                header: l10n.languageLabel,
                children: [
                  for (final (label, locale) in languages)
                    GroupedRow(
                      title: label,
                      trailing: SelectedCheck(
                        visible: current?.languageCode == locale?.languageCode,
                      ),
                      onTap: () =>
                          ref.read(localeProvider.notifier).setLocale(locale),
                    ),
                ],
              ),
              GroupedSection(
                header: l10n.notificationsLabel,
                footer: l10n.menuNotificationsSubtitle,
                children: const [_MenuNotificationsRow()],
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuNotificationsRow extends ConsumerWidget {
  const _MenuNotificationsRow();

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      await ref.read(menuNotificationsProvider.notifier).setEnabled(enabled);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.notificationsSyncFailed(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(menuNotificationsProvider);

    return GroupedRow(
      leading: const IconTile(
        icon: CupertinoIcons.bell_fill,
        color: Color(0xFFFF3B30),
      ),
      title: l10n.menuNotifications,
      trailing: CupertinoSwitch(
        value: enabled,
        activeTrackColor: context.palette.success,
        onChanged: (value) => _toggle(context, ref, value),
      ),
    );
  }
}
