import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// Full width filled button in the accent color. Shows a spinner instead of
/// the label while [loading].
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null && !loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.4 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: loading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      label,
                      style: AppText.headline.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Borderless accent text button.
class PlainButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const PlainButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 1,
      pressedOpacity: 0.4,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: context.palette.accent),
        ),
      ),
    );
  }
}
