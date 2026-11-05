import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../providers/menu_notifications_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionHeader(label: l10n.languageLabel),
          _LanguageOption(label: l10n.systemDefault, value: null, current: current),
          _LanguageOption(label: 'English', value: const Locale('en'), current: current),
          _LanguageOption(label: 'Ελληνικά', value: const Locale('el'), current: current),
          _SectionHeader(label: l10n.notificationsLabel),
          const _MenuNotificationsSwitch(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuNotificationsSwitch extends ConsumerWidget {
  const _MenuNotificationsSwitch();

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool enabled) async {
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

    return SwitchListTile(
      title: Text(l10n.menuNotifications),
      subtitle: Text(l10n.menuNotificationsSubtitle),
      value: enabled,
      onChanged: (value) => _toggle(context, ref, value),
    );
  }
}

class _LanguageOption extends ConsumerWidget {
  final String label;
  final Locale? value;
  final Locale? current;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.current,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = current?.languageCode == value?.languageCode;

    return ListTile(
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => ref.read(localeProvider.notifier).setLocale(value),
    );
  }
}
