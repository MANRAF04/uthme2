import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'buttons.dart';

/// Centered empty, error or loading state.
class StatusView extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  const StatusView({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  const StatusView.loading({super.key, required this.title})
    : icon = null,
      message = null,
      actionLabel = null,
      onAction = null,
      loading = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 12),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppText.subheadline.copyWith(color: p.secondaryLabel),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 52, color: p.tertiaryLabel),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.title3.copyWith(color: p.label),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppText.subheadline.copyWith(color: p.secondaryLabel),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: PrimaryButton(label: actionLabel!, onTap: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
