import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Tells the user the screen is rendering the copy saved on this device
/// because the server could not be reached.
class SavedDataBanner extends StatelessWidget {
  final String title;
  final DateTime? fetchedAt;
  final VoidCallback? onRetry;
  final bool isError;

  const SavedDataBanner({
    super.key,
    required this.title,
    this.fetchedAt,
    this.onRetry,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final savedAt = fetchedAt;
    final tint = isError ? p.danger : p.warning;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_circle_fill
                : CupertinoIcons.wifi_slash,
            size: 22,
            color: tint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.subheadline.copyWith(
                    color: p.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (savedAt != null)
                  Text(
                    l10n.lastUpdated(
                      DateFormat('d MMM, HH:mm', localeName).format(savedAt),
                    ),
                    style: figures(
                      AppText.footnote,
                    ).copyWith(color: p.secondaryLabel),
                  ),
              ],
            ),
          ),
          if (onRetry != null)
            Pressable(
              pressedScale: 1,
              pressedOpacity: 0.4,
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  l10n.retry,
                  style: AppText.subheadline.copyWith(
                    color: p.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
