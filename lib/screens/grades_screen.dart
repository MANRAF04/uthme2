import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/grade.dart';
import '../models/grade_stats.dart';
import '../models/grades_snapshot.dart';
import '../providers/average_mode_controller.dart';
import '../providers/grades_provider.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/grade_ring.dart';
import '../widgets/large_title_bar.dart';
import '../widgets/saved_data_banner.dart';
import '../widgets/segmented_control.dart';
import '../widgets/status_view.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);
    final l10n = AppLocalizations.of(context);
    final refreshing = gradesAsync.value?.isRefreshing ?? false;
    Future<void> refresh() => ref.read(gradesProvider.notifier).refreshGrades();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleBar(
            title: l10n.myGrades,
            actions: [
              if (refreshing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CupertinoActivityIndicator(),
                ),
            ],
          ),
          if (gradesAsync.hasValue)
            CupertinoSliverRefreshControl(onRefresh: refresh),
          ...gradesAsync.when(
            loading: () => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView.loading(title: l10n.fetchingGrades),
              ),
            ],
            error: (error, stack) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView(
                  icon: CupertinoIcons.wifi_exclamationmark,
                  title: l10n.couldNotReachPortal,
                  message: l10n.checkConnection,
                  actionLabel: l10n.retry,
                  onAction: refresh,
                ),
              ),
            ],
            data: (snapshot) => snapshot.grades.isEmpty
                ? [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: StatusView(
                        icon: CupertinoIcons.doc_text_search,
                        title: l10n.noGradesYet,
                        message: l10n.noGradesYetSubtitle,
                      ),
                    ),
                  ]
                : [_GradesContent(snapshot: snapshot, onRetry: refresh)],
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
          ),
        ],
      ),
    );
  }
}

class _GradesContent extends ConsumerStatefulWidget {
  final GradesSnapshot snapshot;
  final VoidCallback onRetry;

  const _GradesContent({required this.snapshot, required this.onRetry});

  @override
  ConsumerState<_GradesContent> createState() => _GradesContentState();
}

class _GradesContentState extends ConsumerState<_GradesContent> {
  /// Semesters the user opened or closed. Untouched ones fall back to the
  /// default: only the latest semester starts open.
  final Map<int, bool> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weighted = ref.watch(averageWeightedProvider);
    final grades = widget.snapshot.grades;
    final stats = GradeStats.from(grades, weighted: weighted);
    final bySemester = groupBy(grades, (Grade g) => g.semester);
    final semesters = bySemester.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList.list(
      children: [
        if (widget.snapshot.isStale)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SavedDataBanner(
              title: l10n.showingSavedGrades,
              fetchedAt: widget.snapshot.fetchedAt,
              onRetry: widget.onRetry,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: _SummaryCard(
            stats: stats,
            weighted: weighted,
            onModeChanged: (index) async {
              if ((index == 0) == weighted) return;
              await ref.read(averageWeightedProvider.notifier).toggle();
              await WidgetService.syncFromGrades(grades);
            },
          ),
        ),
        for (final semester in semesters)
          _SemesterCard(
            semester: semester,
            grades: bySemester[semester]!,
            weighted: weighted,
            expanded: _expanded[semester] ?? semester == semesters.first,
            onToggle: () => setState(() {
              _expanded[semester] =
                  !(_expanded[semester] ?? semester == semesters.first);
            }),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final GradeStats stats;
  final bool weighted;
  final ValueChanged<int> onModeChanged;

  const _SummaryCard({
    required this.stats,
    required this.weighted,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final lastGrade = stats.lastGrade?.toStringAsFixed(1) ?? '–';

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.lg + 2),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              GradeRing(
                value: stats.average,
                size: 124,
                textColor: p.label,
                secondaryTextColor: p.secondaryLabel,
                trackColor: p.fill,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stat(
                      value: '${stats.passedCount}',
                      label: l10n.passed,
                      color: p.success,
                    ),
                    const SizedBox(height: 10),
                    _Stat(
                      value: '${stats.totalEcts}',
                      label: l10n.ectsEarned,
                      color: p.label,
                    ),
                    const SizedBox(height: 10),
                    _Stat(
                      value: lastGrade,
                      label: stats.lastGradeTitle ?? l10n.lastGrade,
                      color: p.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SegmentedControl(
            labels: [l10n.averageWeighted, l10n.averageSimple],
            selected: weighted ? 0 : 1,
            onChanged: onModeChanged,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: figures(AppText.title2).copyWith(color: color, height: 1.1),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.footnote.copyWith(color: p.secondaryLabel),
        ),
      ],
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final int semester;
  final List<Grade> grades;
  final bool weighted;
  final bool expanded;
  final VoidCallback onToggle;

  const _SemesterCard({
    required this.semester,
    required this.grades,
    required this.weighted,
    required this.expanded,
    required this.onToggle,
  });

  /// Null when the semester has nothing that counts towards the average yet.
  double? get _average {
    final counts = grades.any(
      (g) => g.passed && g.grade != null && (!weighted || g.ects > 0),
    );
    return counts ? GradeStats.from(grades, weighted: weighted).average : null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final average = _average;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ColoredBox(
          color: p.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                expanded: expanded,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.semester(semester),
                                style: AppText.headline.copyWith(
                                  color: p.label,
                                ),
                              ),
                              Text(
                                l10n.subjectCount(grades.length),
                                style: AppText.footnote.copyWith(
                                  color: p.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (average != null)
                          Text(
                            average.toStringAsFixed(2),
                            style: figures(
                              AppText.headline,
                            ).copyWith(color: p.secondaryLabel),
                          ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: expanded ? 0.25 : 0,
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            CupertinoIcons.chevron_forward,
                            size: 17,
                            color: p.tertiaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final grade in grades) _CourseRow(grade: grade),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final Grade grade;

  const _CourseRow({required this.grade});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(height: 0.5, color: p.separator),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.callout.copyWith(color: p.label),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${grade.code} · ${grade.ects} ECTS',
                      style: figures(
                        AppText.footnote,
                      ).copyWith(color: p.secondaryLabel),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _GradePill(grade: grade),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradePill extends StatelessWidget {
  final Grade grade;

  const _GradePill({required this.grade});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = grade.grade;
    final color = value == null
        ? p.tertiaryLabel
        : (grade.passed ? p.success : p.danger);

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value == null ? p.fill : color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        value?.toString() ?? '–',
        style: figures(AppText.headline).copyWith(color: color),
      ),
    );
  }
}
