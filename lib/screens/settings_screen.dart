import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.languageLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _LanguageOption(label: l10n.systemDefault, value: null, current: current),
          _LanguageOption(label: 'English', value: const Locale('en'), current: current),
          _LanguageOption(label: 'Ελληνικά', value: const Locale('el'), current: current),
        ],
      ),
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
