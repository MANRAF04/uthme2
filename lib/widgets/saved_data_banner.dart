import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Tells the user the screen is rendering the copy saved on this device
/// because the server could not be reached.
class SavedDataBanner extends StatelessWidget {
  final String title;
  final DateTime? fetchedAt;
  final VoidCallback? onRetry;

  const SavedDataBanner({
    super.key,
    required this.title,
    this.fetchedAt,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final savedAt = fetchedAt;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amberArc.withValues(alpha: 0.40)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 20, color: AppColors.amberArc),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (savedAt != null)
                  Text(
                    l10n.lastUpdated(
                      DateFormat('d MMM, HH:mm', localeName).format(savedAt),
                    ),
                    style: monoStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
