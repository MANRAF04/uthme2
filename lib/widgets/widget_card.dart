import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/grade_stats.dart';
import '../theme/app_theme.dart';
import 'grade_ring.dart';

/// Fixed-size, self-contained version of the grades hero card, used as the
/// render target for the Android home-screen widget image. Mirrors the in-app
/// card: gauge on the left, stats on the right, last grade with course name.
class WidgetCard extends StatelessWidget {
  final GradeStats stats;
  final AppLocalizations l10n;
  final bool loading;
  final Size logicalSize;

  const WidgetCard({
    super.key,
    required this.stats,
    required this.l10n,
    this.loading = false,
    this.logicalSize = const Size(360, 210),
  });

  @override
  Widget build(BuildContext context) {
    final lastGradeStr =
        stats.lastGrade != null ? stats.lastGrade!.toStringAsFixed(1) : '—';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: logicalSize.width,
        height: logicalSize.height,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loading ? l10n.refreshing : l10n.weightedAverage,
                style: monoStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradeRing(value: stats.average, size: 116, animate: false),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _stat(
                          '${stats.passedCount}',
                          l10n.passed,
                          const Color(0xFF4FE0D2),
                        ),
                        const SizedBox(height: 12),
                        _stat(
                          '${stats.totalEcts}',
                          l10n.ectsEarned,
                          AppColors.amber,
                        ),
                        const SizedBox(height: 12),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: monoStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
      ],
    );
  }
}
