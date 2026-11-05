import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import 'grades_screen.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';

enum HomeTab { grades, menu, settings }

/// Signed-in root: Grades, Menu and Settings behind a translucent tab bar.
/// Tabs are built on first visit and then kept alive, so switching back
/// never reloads a screen.
class HomeShell extends StatefulWidget {
  final HomeTab initialTab;

  const HomeShell({super.key, this.initialTab = HomeTab.grades});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late HomeTab _tab = widget.initialTab;
  late final Set<HomeTab> _visited = {widget.initialTab};
  StreamSubscription<void>? _menuOpened;

  @override
  void initState() {
    super.initState();
    _menuOpened = PushService.onMenuOpened.listen((_) => _select(HomeTab.menu));
  }

  @override
  void dispose() {
    _menuOpened?.cancel();
    super.dispose();
  }

  void _select(HomeTab tab) {
    if (!mounted || tab == _tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  Widget _screen(HomeTab tab) {
    if (!_visited.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      HomeTab.grades => const GradesScreen(),
      HomeTab.menu => const RestaurantMenuScreen(),
      HomeTab.settings => const SettingsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab.index,
        children: [
          for (final tab in HomeTab.values)
            TickerMode(enabled: tab == _tab, child: _screen(tab)),
        ],
      ),
      bottomNavigationBar: _TabBar(
        selected: _tab,
        onSelect: (tab) {
          HapticFeedback.selectionClick();
          _select(tab);
        },
        items: [
          _TabItem(
            label: l10n.tabGrades,
            icon: CupertinoIcons.chart_bar_square,
            selectedIcon: CupertinoIcons.chart_bar_square_fill,
          ),
          _TabItem(
            label: l10n.tabMenu,
            icon: Icons.restaurant_outlined,
            selectedIcon: Icons.restaurant,
          ),
          _TabItem(
            label: l10n.settings,
            icon: CupertinoIcons.gear_alt,
            selectedIcon: CupertinoIcons.gear_alt_fill,
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _TabBar extends StatelessWidget {
  final HomeTab selected;
  final ValueChanged<HomeTab> onSelect;
  final List<_TabItem> items;

  const _TabBar({
    required this.selected,
    required this.onSelect,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: p.barBackground,
            border: Border(top: BorderSide(color: p.separator, width: 0.5)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          height: 52 + bottomInset,
          child: Row(
            children: [
              for (final tab in HomeTab.values)
                Expanded(
                  child: _TabButton(
                    item: items[tab.index],
                    selected: tab == selected,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.accent : p.secondaryLabel;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 25,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
