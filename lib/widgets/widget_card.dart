import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/grade_stats.dart';
import '../theme/app_theme.dart';
import 'grade_ring.dart';

/// Fixed-size, self-contained summary card, rendered to an image for the
/// Android home screen widget. Always dark so it reads on any wallpaper.
class WidgetCard extends StatelessWidget {
  final GradeStats stats;
  final AppLocalizations l10n;
  final bool loading;
  final bool weighted;
  final Size logicalSize;

  const WidgetCard({
    super.key,
    required this.stats,
    required this.l10n,
    this.loading = false,
    this.weighted = true,
    this.logicalSize = const Size(360, 210),
  });

  static const _card = Color(0xFF1C1C1E);
  static const _secondary = Color(0x99EBEBF5);

  @override
  Widget build(BuildContext context) {
    final lastGradeStr = stats.lastGrade != null
        ? stats.lastGrade!.toStringAsFixed(1)
        : '–';
    final heading = loading
        ? l10n.refreshing
        : (weighted ? l10n.weightedAverage : l10n.unweightedAverage);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: logicalSize.width,
        height: logicalSize.height,
        child: Container(
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: _secondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  GradeRing(
                    value: stats.average,
                    size: 120,
                    animate: false,
                    textColor: Colors.white,
                    secondaryTextColor: _secondary,
                    trackColor: Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stat(
                          '${stats.passedCount}',
                          l10n.passed,
                          const Color(0xFF34D3C4),
                        ),
                        const SizedBox(height: 8),
                        _stat(
                          '${stats.totalEcts}',
                          l10n.ectsEarned,
                          AppColors.amber,
                        ),
                        const SizedBox(height: 8),
                        _stat(
                          lastGradeStr,
                          stats.lastGradeTitle ?? l10n.lastGrade,
                          Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: figures(AppText.title3).copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(color: _secondary),
        ),
      ],
    );
  }
}
