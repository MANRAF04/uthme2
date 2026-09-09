import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:collection/collection.dart';
import '../l10n/app_localizations.dart';
import '../providers/average_mode_controller.dart';
import '../providers/grades_provider.dart';
import '../models/grade.dart';
import '../models/grade_stats.dart';
import '../services/cache_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/grade_ring.dart';
import '../widgets/saved_data_banner.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.invalidate(gradesProvider);
    const storage = FlutterSecureStorage();
    final username = (await storage.read(key: 'username'))?.trim();

    if (username != null && username.isNotEmpty) {
      await CacheService.clearGrades(username);
    }
    await storage.delete(key: 'username');
    await storage.delete(key: 'password');

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsyncValue = ref.watch(gradesProvider);
    final weighted = ref.watch(averageWeightedProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myGrades),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: l10n.universityMenus,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestaurantMenuScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.logOut,
            onPressed: () => _logout(context, ref),
          ),
        ],
        // Saved grades are on screen already; the refresh runs behind them.
        bottom: (gradesAsyncValue.value?.isRefreshing ?? false)
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: gradesAsyncValue.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.fetchingGrades,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.coralDeep,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.couldNotReachPortal,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.checkConnection,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      ref.read(gradesProvider.notifier).refreshGrades(),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (snapshot) {
          final grades = snapshot.grades;

          if (grades.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.noGradesYet,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noGradesYetSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Overall average (weighted or plain mean) and headline stats.
          final stats = GradeStats.from(grades, weighted: weighted);
          final String lastGradeStr = stats.lastGrade != null
              ? stats.lastGrade!.toStringAsFixed(1)
              : '—';

          final groupedGrades = groupBy(grades, (g) => g.semester);
          final semesters = groupedGrades.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () => ref.read(gradesProvider.notifier).refreshGrades(),
            child: CustomScrollView(
              slivers: [
                if (snapshot.isStale)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: SavedDataBanner(
                        title: l10n.showingSavedGrades,
                        fetchedAt: snapshot.fetchedAt,
                        onRetry: () =>
                            ref.read(gradesProvider.notifier).refreshGrades(),
                      ),
                    ),
                  ),

                // HERO card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.heroGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.xl),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _averageToggle(
                                context, ref, l10n, weighted, grades),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GradeRing(value: stats.average, size: 116),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // passed
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${stats.passedCount}',
                                          style: monoStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF4FE0D2),
                                          ),
                                        ),
                                        Text(
                                          l10n.passed,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // ECTS
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${stats.totalEcts}',
                                          style: monoStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.amber,
                                          ),
                                        ),
                                        Text(
                                          l10n.ectsEarned,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // last grade
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          lastGradeStr,
                                          style: monoStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          stats.lastGradeTitle ?? l10n.lastGrade,
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
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
                ),

                // Semester list
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final semesterNum = semesters[index];
                        final semesterGrades = groupedGrades[semesterNum]!;

                        // Per-semester average, matching the selected mode.
                        double semWeighted = 0;
                        int semEcts = 0;
                        double semSum = 0;
                        int semGraded = 0;
                        for (final g in semesterGrades) {
                          if (g.passed && g.grade != null) {
                            semSum += g.grade!;
                            semGraded++;
                            if (g.ects > 0) {
                              semWeighted += g.grade! * g.ects;
                              semEcts += g.ects;
                            }
                          }
                        }
                        final double? semAvg = weighted
                            ? (semEcts > 0 ? semWeighted / semEcts : null)
                            : (semGraded > 0 ? semSum / semGraded : null);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            initiallyExpanded: index == 0,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.coral,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.semester(semesterNum),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        l10n.subjectCount(semesterGrades.length),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (semAvg != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      semAvg.toStringAsFixed(2),
                                      style: monoStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.tealDeep,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            children: semesterGrades
                                .map((grade) => _subjectRow(context, grade))
                                .toList(),
                          ),
                        );
                      },
                      childCount: semesters.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _averageToggle(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool weighted,
    List<Grade> grades,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () async {
          await ref.read(averageWeightedProvider.notifier).toggle();
          await WidgetService.syncFromGrades(grades);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horiz,
                size: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                weighted ? l10n.weightedAverage : l10n.unweightedAverage,
                style: monoStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectRow(BuildContext context, Grade grade) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${grade.code} · ${grade.ects} ECTS',
                  style: monoStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _gradeBadge(context, grade),
        ],
      ),
    );
  }

  Widget _gradeBadge(BuildContext context, Grade grade) {
    final Color bgColor;
    final Color textColor;

    if (grade.grade == null) {
      bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (grade.passed) {
      bgColor = AppColors.teal.withValues(alpha: 0.14);
      textColor = AppColors.tealDeep;
    } else {
      bgColor = AppColors.coral.withValues(alpha: 0.14);
      textColor = AppColors.coralDeep;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        grade.grade?.toString() ?? '—',
        style: monoStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
