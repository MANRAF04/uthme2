import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../l10n/app_localizations.dart';
import '../models/student_profile.dart';
import '../providers/grades_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped.dart';
import '../widgets/large_title_bar.dart';
import '../widgets/saved_data_banner.dart';
import '../widgets/status_view.dart';

/// Student number, academic ID and, when free meals apply, the academic ID
/// as a Code128 barcode for the restaurant scanner. The profile rides along
/// with grades, so this screen reads the grades provider.
class StudentIdScreen extends ConsumerWidget {
  const StudentIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gradesAsync = ref.watch(gradesProvider);
    final refreshing = gradesAsync.value?.isRefreshing ?? false;
    Future<void> refresh() => ref.read(gradesProvider.notifier).refreshGrades();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleBar(
            title: l10n.studentId,
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
            loading: () => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator(radius: 12)),
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
            data: (snapshot) {
              final profile = snapshot.profile;
              return [
                if (snapshot.isStale)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: SavedDataBanner(
                        title: l10n.showingSavedGrades,
                        fetchedAt: snapshot.fetchedAt,
                        onRetry: refresh,
                      ),
                    ),
                  ),
                if (profile == null || !profile.hasIdentity)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: StatusView(
                      icon: CupertinoIcons.person_crop_rectangle,
                      title: l10n.noStudentDetails,
                      message: l10n.noStudentDetailsSubtitle,
                    ),
                  )
                else
                  SliverToBoxAdapter(child: _ProfileDetails(profile: profile)),
              ];
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final StudentProfile profile;

  const _ProfileDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final academicNo = profile.academicNo;
    final card = profile.diningCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: profile.freeMeals && academicNo != null
              ? _BrightnessBoost(child: _BarcodeCard(data: academicNo))
              : _NoBarcodeCard(
                  title: card == null
                      ? l10n.noDiningCard
                      : l10n.freeMealsUnavailable,
                ),
        ),
        GroupedSection(
          header: l10n.studentId,
          children: [
            _CopyRow(label: l10n.studentNumber, value: profile.studentNo),
            _CopyRow(label: l10n.academicIdNumber, value: academicNo),
          ],
        ),
        if (card != null)
          GroupedSection(
            header: l10n.diningCard,
            footer: _validity(context, card),
            children: [
              GroupedRow(
                title: l10n.diningCard,
                trailing: _StatusPill(
                  label: card.active
                      ? l10n.diningCardActive
                      : l10n.diningCardInactive,
                  active: card.active,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String? _validity(BuildContext context, DiningCard card) {
    final from = card.validFromDate;
    final to = card.validToDate;
    if (from == null || to == null) return null;

    final format = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return AppLocalizations.of(
      context,
    ).diningCardValidity(format.format(from), format.format(to));
  }
}

/// Always black on white, in dark mode too: scanners need the contrast.
class _BarcodeCard extends StatelessWidget {
  final String data;

  const _BarcodeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg + 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Semantics(
                label: '${l10n.academicIdNumber} $data',
                excludeSemantics: true,
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: data,
                  height: 96,
                  drawText: false,
                  color: Colors.black,
                  errorBuilder: (context, error) => const SizedBox(height: 96),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data,
                style: figures(
                  AppText.title3,
                ).copyWith(color: Colors.black, letterSpacing: 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.scanAtRestaurant,
          textAlign: TextAlign.center,
          style: AppText.footnote.copyWith(color: p.secondaryLabel),
        ),
      ],
    );
  }
}

class _NoBarcodeCard extends StatelessWidget {
  final String title;

  const _NoBarcodeCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.lg + 2),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.barcode, size: 44, color: p.tertiaryLabel),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

/// Label above a value; tapping copies the value.
class _CopyRow extends StatelessWidget {
  final String label;
  final String? value;

  const _CopyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = value;

    return GroupedRow(
      title: text ?? '–',
      subtitle: label,
      trailing: text == null
          ? null
          : Icon(CupertinoIcons.doc_on_doc, size: 18, color: p.tertiaryLabel),
      onTap: text == null
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: text));
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).copied),
                    duration: const Duration(seconds: 1),
                  ),
                );
            },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.success : p.secondaryLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.13) : p.fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.footnote.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Raises this app's screen brightness to full while [child] is on screen,
/// like wallet passes, and hands control back to the system when it leaves.
/// Only the app window is affected, so backgrounding the app restores the
/// user's brightness on its own.
class _BrightnessBoost extends StatefulWidget {
  final Widget child;

  const _BrightnessBoost({required this.child});

  @override
  State<_BrightnessBoost> createState() => _BrightnessBoostState();
}

class _BrightnessBoostState extends State<_BrightnessBoost> {
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _set(boost: true);
  }

  @override
  void dispose() {
    _set(boost: false);
    super.dispose();
  }

  Future<void> _set({required bool boost}) async {
    if (!_supported) return;
    try {
      final brightness = ScreenBrightness.instance;
      if (boost) {
        await brightness.setApplicationScreenBrightness(1.0);
      } else {
        await brightness.resetApplicationScreenBrightness();
      }
    } catch (_) {
      // Brightness is a convenience; the barcode works without it.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
