import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// Pinned iOS style navigation bar with a large title that collapses into a
/// small centered one. Once content scrolls under it the bar turns into a
/// translucent blurred material with a hairline edge.
class LargeTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback? onTitleTap;
  final List<Widget> actions;
  final Widget? bottom;
  final double bottomHeight;

  const LargeTitleBar({
    super.key,
    required this.title,
    this.onTitleTap,
    this.actions = const [],
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LargeTitleDelegate(
        title: title,
        onTitleTap: onTitleTap,
        actions: actions,
        bottom: bottom,
        bottomHeight: bottom == null ? 0 : bottomHeight,
        topPadding: MediaQuery.paddingOf(context).top,
        canPop: Navigator.of(context).canPop(),
      ),
    );
  }
}

class _LargeTitleDelegate extends SliverPersistentHeaderDelegate {
  static const double _toolbar = 44;
  static const double _largeTitle = 52;

  final String title;
  final VoidCallback? onTitleTap;
  final List<Widget> actions;
  final Widget? bottom;
  final double bottomHeight;
  final double topPadding;
  final bool canPop;

  _LargeTitleDelegate({
    required this.title,
    required this.onTitleTap,
    required this.actions,
    required this.bottom,
    required this.bottomHeight,
    required this.topPadding,
    required this.canPop,
  });

  @override
  double get minExtent => topPadding + _toolbar + bottomHeight;

  @override
  double get maxExtent => minExtent + _largeTitle;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final p = context.palette;
    final collapse = (shrinkOffset / _largeTitle).clamp(0.0, 1.0);
    final material = ((collapse - 0.7) / 0.3).clamp(0.0, 1.0);
    final smallTitle = ((collapse - 0.8) / 0.2).clamp(0.0, 1.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20 * material, sigmaY: 20 * material),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(p.background, p.barBackground, material),
            border: Border(
              bottom: BorderSide(
                color: p.separator.withValues(alpha: p.separator.a * material),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                bottom: bottomHeight + 6,
                child: Opacity(
                  opacity: 1 - collapse,
                  child: _TitleText(
                    title: title,
                    style: AppText.largeTitle.copyWith(color: p.label),
                    onTap: onTitleTap,
                    chevronSize: 22,
                  ),
                ),
              ),
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: _toolbar,
                child: _Toolbar(
                  canPop: canPop,
                  actions: actions,
                  title: Opacity(
                    opacity: smallTitle,
                    child: _TitleText(
                      title: title,
                      style: AppText.headline.copyWith(color: p.label),
                      onTap: smallTitle > 0 ? onTitleTap : null,
                      chevronSize: 14,
                    ),
                  ),
                ),
              ),
              if (bottom != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomHeight,
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleDelegate oldDelegate) => true;
}

class _Toolbar extends StatelessWidget {
  final bool canPop;
  final List<Widget> actions;
  final Widget title;

  const _Toolbar({
    required this.canPop,
    required this.actions,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return NavigationToolbar(
      leading: canPop
          ? Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              child: Pressable(
                pressedScale: 1,
                pressedOpacity: 0.4,
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    CupertinoIcons.chevron_back,
                    color: p.accent,
                    size: 26,
                  ),
                ),
              ),
            )
          : null,
      middle: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: title,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: actions),
      ),
      middleSpacing: 0,
    );
  }
}

class _TitleText extends StatelessWidget {
  final String title;
  final TextStyle style;
  final VoidCallback? onTap;
  final double chevronSize;

  const _TitleText({
    required this.title,
    required this.style,
    required this.onTap,
    required this.chevronSize,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (onTap == null) return text;

    return Pressable(
      pressedScale: 1,
      pressedOpacity: 0.5,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: text),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_down,
            size: chevronSize,
            color: context.palette.accent,
          ),
        ],
      ),
    );
  }
}

/// Circular icon button for the navigation bar.
class BarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const BarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Pressable(
        pressedScale: 1,
        pressedOpacity: 0.4,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Icon(icon, color: context.palette.accent, size: 24),
        ),
      ),
    );
  }
}

/// Text button for the navigation bar, e.g. "Today".
class BarTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const BarTextButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 1,
      pressedOpacity: 0.4,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          label,
          style: AppText.body.copyWith(color: context.palette.accent),
        ),
      ),
    );
  }
}
