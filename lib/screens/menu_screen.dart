import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/restaurant.dart';
import '../models/restaurant_menu.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped.dart';
import '../widgets/large_title_bar.dart';
import '../widgets/saved_data_banner.dart';
import '../widgets/status_view.dart';

class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _preferredPrefix = 'preferred_restaurant_id_';
  static const String _legacyPreferredKey = 'preferred_restaurant_id';

  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isBootstrapping = true;
  bool _isLoadingMenu = false;
  bool _isSavingPreference = false;

  String? _errorMessage;
  String? _menuErrorMessage;

  List<UniversityRestaurant> _restaurants = const [];
  String? _selectedRestaurantId;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _loadedRestaurantId;
  DateTime? _loadedRangeStart;
  DateTime? _loadedRangeEnd;
  List<MealTypeWindow> _mealTypes = const [];
  Map<String, List<RestaurantMenuItem>> _menuByDate = const {};
  DateTime? _menuFetchedAt;
  bool _menuFromCache = false;

  /// +1 when the last day change moved forward, -1 backward. Drives which
  /// side the new day slides in from.
  int _direction = 1;

  AppLocalizations get _l10n => AppLocalizations.of(context);
  String get _localeName => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isBootstrapping = true;
      _errorMessage = null;
    });

    final preferredRestaurant = await _readPreferredRestaurant();
    final cached = await CacheService.readRestaurants();

    // Saved list first: picker and menu stay usable with an unreachable server.
    if (cached != null && cached.data.isNotEmpty) {
      if (!mounted) return;
      _applyRestaurants(cached.data, preferredRestaurant);
      setState(() {
        _isBootstrapping = false;
      });

      if (_selectedRestaurantId != null) {
        await _loadMenuForDate(_selectedDate, forceReload: true);
      }
      await _refreshRestaurants();
      return;
    }

    try {
      final restaurants = await _api.fetchRestaurants();
      if (restaurants.isNotEmpty) {
        await CacheService.writeRestaurants(restaurants);
      }

      if (!mounted) return;
      _applyRestaurants(restaurants, preferredRestaurant);

      if (restaurants.isEmpty) {
        setState(() {
          _errorMessage = _l10n.noRestaurantsAvailable;
          _isBootstrapping = false;
        });
        return;
      }

      if (_selectedRestaurantId != null) {
        await _loadMenuForDate(_selectedDate, forceReload: true);
      }

      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _l10n.couldNotLoadRestaurants(e);
        _isBootstrapping = false;
      });
    }
  }

  void _applyRestaurants(
    List<UniversityRestaurant> restaurants,
    String? preferredRestaurantId,
  ) {
    final selected =
        preferredRestaurantId != null &&
            restaurants.any((r) => r.id == preferredRestaurantId)
        ? preferredRestaurantId
        : null;

    setState(() {
      _restaurants = restaurants;
      _selectedRestaurantId = selected;
    });
  }

  /// Brings the saved restaurant list up to date without disturbing the
  /// screen. A failure changes nothing: the saved list still works.
  Future<void> _refreshRestaurants() async {
    try {
      final restaurants = await _api.fetchRestaurants();
      if (restaurants.isEmpty) return;

      await CacheService.writeRestaurants(restaurants);
      if (!mounted) return;
      setState(() {
        _restaurants = restaurants;
      });
    } catch (_) {
      // Offline: the saved-menu banner already says so.
    }
  }

  Future<String?> _readPreferredRestaurant() async {
    final username = (await _storage.read(key: _usernameKey))?.trim();

    if (username != null && username.isNotEmpty) {
      final key = '$_preferredPrefix$username';
      final saved = await _storage.read(key: key);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    }

    final legacy = await _storage.read(key: _legacyPreferredKey);
    return legacy?.isNotEmpty == true ? legacy : null;
  }

  Future<void> _savePreferredRestaurant(String restaurantId) async {
    setState(() {
      _isSavingPreference = true;
      _selectedRestaurantId = restaurantId;
      _menuErrorMessage = null;
    });

    final username = (await _storage.read(key: _usernameKey))?.trim();
    final password = await _storage.read(key: _passwordKey);

    if (username != null && username.isNotEmpty) {
      await _storage.write(
        key: '$_preferredPrefix$username',
        value: restaurantId,
      );
    } else {
      await _storage.write(key: _legacyPreferredKey, value: restaurantId);
    }

    try {
      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        await _api.savePreferredRestaurant(
          username: username,
          password: password,
          restaurantId: restaurantId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.preferenceSyncFailed(e))));
      }
    }

    if (!mounted) return;
    setState(() {
      _isSavingPreference = false;
    });

    await _loadMenuForDate(_selectedDate, forceReload: true);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadMenuForDate(
    DateTime date, {
    bool forceReload = false,
  }) async {
    final restaurantId = _selectedRestaurantId;
    if (restaurantId == null) return;

    final normalizedDate = DateUtils.dateOnly(date);

    if (!forceReload && _isDateInLoadedRange(normalizedDate)) {
      setState(() {
        _selectedDate = normalizedDate;
      });
      return;
    }

    final weekStart = _startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    setState(() {
      _selectedDate = normalizedDate;
      _isLoadingMenu = true;
      _menuErrorMessage = null;
    });

    // Paint the saved week first, but only when it is the week being asked for.
    final cached = await CacheService.readMenu(
      restaurantId: restaurantId,
      startDate: weekStart,
      endDate: weekEnd,
    );

    if (cached != null && mounted) {
      _applyMenu(
        cached.data,
        restaurantId: restaurantId,
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }

    try {
      final response = await _api.fetchRestaurantMenu(
        restaurantId,
        startDate: weekStart,
        endDate: weekEnd,
      );
      await CacheService.writeMenu(
        restaurantId: restaurantId,
        startDate: weekStart,
        endDate: weekEnd,
        menu: response,
      );

      if (!mounted) return;
      _applyMenu(
        response,
        restaurantId: restaurantId,
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
    } catch (e) {
      if (!mounted) return;
      // With the saved week on screen the banner explains itself; an error
      // message only helps when there is nothing to show.
      if (cached == null) {
        setState(() {
          _menuErrorMessage = _l10n.couldNotLoadMenu(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMenu = false;
        });
      }
    }
  }

  void _applyMenu(
    RestaurantMenuRange menu, {
    required String restaurantId,
    required DateTime? fetchedAt,
    required bool fromCache,
  }) {
    setState(() {
      _loadedRestaurantId = restaurantId;
      _loadedRangeStart = DateUtils.dateOnly(menu.startDate);
      _loadedRangeEnd = DateUtils.dateOnly(menu.endDate);
      _mealTypes = menu.mealTypes;
      _menuByDate = groupBy(menu.items, (item) => _dateKey(item.date));
      _menuFetchedAt = fetchedAt;
      _menuFromCache = fromCache;
    });
  }

  /// Whether the loaded payload actually covers what the screen is showing.
  /// A payload from another restaurant never counts, so switching restaurants
  /// cannot leave the previous one's food on screen.
  bool _isDateInLoadedRange(DateTime date) {
    final start = _loadedRangeStart;
    final end = _loadedRangeEnd;
    if (start == null || end == null) return false;
    if (_loadedRestaurantId != _selectedRestaurantId) return false;

    return !date.isBefore(start) && !date.isAfter(end);
  }

  Future<void> _goToDate(DateTime date) async {
    final target = DateUtils.dateOnly(date);
    if (target == _selectedDate || !_canGoTo(target)) return;

    HapticFeedback.selectionClick();
    setState(() => _direction = target.isAfter(_selectedDate) ? 1 : -1);
    await _loadMenuForDate(target);
  }

  Future<void> _changeDay(int offset) =>
      _goToDate(_selectedDate.add(Duration(days: offset)));

  /// While a reload is in flight only moves inside the loaded week are allowed,
  /// so two fetches can never race to fill the same screen.
  bool _canGoTo(DateTime date) =>
      !_isLoadingMenu || _isDateInLoadedRange(DateUtils.dateOnly(date));

  List<RestaurantMenuItem> _menuItemsForSelectedDate() {
    final items = List<RestaurantMenuItem>.from(
      _menuByDate[_dateKey(_selectedDate)] ?? const <RestaurantMenuItem>[],
    );

    items.sort((a, b) {
      final mealCompare = a.mealTypeSortOrder.compareTo(b.mealTypeSortOrder);
      if (mealCompare != 0) return mealCompare;
      final courseCompare = a.courseSortOrder.compareTo(b.courseSortOrder);
      if (courseCompare != 0) return courseCompare;
      final itemCompare = a.itemSortOrder.compareTo(b.itemSortOrder);
      if (itemCompare != 0) return itemCompare;
      return a.foodName.compareTo(b.foodName);
    });

    return items;
  }

  bool _isSelectedDateToday() {
    final now = DateUtils.dateOnly(DateTime.now());
    return now == _selectedDate;
  }

  int? _parseClockToMinutes(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return null;

    return hours * 60 + minutes;
  }

  int _findCurrentOrNextSectionIndex(List<_MealSection> sections) {
    if (sections.length <= 1) return 0;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    int? nextIndex;

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final fromMinutes = _parseClockToMinutes(section.hourFrom);
      final toMinutes = _parseClockToMinutes(section.hourTo);

      if (fromMinutes == null || toMinutes == null) continue;

      final isCurrent =
          currentMinutes >= fromMinutes && currentMinutes < toMinutes;
      if (isCurrent) {
        return i;
      }

      if (nextIndex == null && currentMinutes < fromMinutes) {
        nextIndex = i;
      }
    }

    return nextIndex ?? 0;
  }

  List<_MealSection> _mealSectionsForSelectedDate() {
    final items = _menuItemsForSelectedDate();
    if (items.isEmpty) return const [];

    final activeWindows = _mealTypes
        .where((window) => window.isActive)
        .toList();
    final windowByMealTypeId = {
      for (final window in activeWindows)
        if (window.mealTypeId.isNotEmpty) window.mealTypeId: window,
    };

    final grouped = <String, List<RestaurantMenuItem>>{};
    for (final item in items) {
      final key = item.mealTypeId.isNotEmpty ? item.mealTypeId : item.mealType;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sections = <_MealSection>[];
    grouped.forEach((key, mealItems) {
      final sample = mealItems.first;
      final window = windowByMealTypeId[sample.mealTypeId];

      final sectionItems = List<RestaurantMenuItem>.from(mealItems)
        ..sort((a, b) {
          final courseCompare = a.courseSortOrder.compareTo(b.courseSortOrder);
          if (courseCompare != 0) return courseCompare;
          final itemCompare = a.itemSortOrder.compareTo(b.itemSortOrder);
          if (itemCompare != 0) return itemCompare;
          return a.foodName.compareTo(b.foodName);
        });

      sections.add(
        _MealSection(
          title: (window?.title.isNotEmpty ?? false)
              ? window!.title
              : sample.mealType,
          sortOrder: window?.sortOrder ?? sample.mealTypeSortOrder,
          hourFrom: window?.hourFrom ?? sample.mealHourFrom,
          hourTo: window?.hourTo ?? sample.mealHourTo,
          items: sectionItems,
        ),
      );
    });

    sections.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.title.compareTo(b.title);
    });

    if (_isSelectedDateToday()) {
      final pivot = _findCurrentOrNextSectionIndex(sections);
      if (pivot > 0) {
        return [...sections.sublist(pivot), ...sections.sublist(0, pivot)];
      }
    }

    return sections;
  }

  String _dayTitle(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = date.difference(today).inDays;

    if (diff == 0) return _l10n.today;
    if (diff == 1) return _l10n.tomorrow;
    if (diff == -1) return _l10n.yesterday;

    return DateFormat.E(_localeName).format(date);
  }

  String _daySubtitle(DateTime date) {
    final weekday = _dayTitle(date);
    final formattedDate = DateFormat('d MMM y', _localeName).format(date);
    return '$weekday, $formattedDate';
  }

  Future<void> _openRestaurantPickerSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final p = context.palette;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                  child: Text(
                    _l10n.pickYourRestaurant,
                    textAlign: TextAlign.center,
                    style: AppText.headline.copyWith(color: p.label),
                  ),
                ),
                GroupedSection(
                  children: [
                    for (final restaurant in _restaurants)
                      GroupedRow(
                        title: restaurant.title,
                        subtitle: restaurant.subtitle,
                        trailing: SelectedCheck(
                          visible: restaurant.id == _selectedRestaurantId,
                        ),
                        onTap: () => Navigator.pop(context, restaurant.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || picked == _selectedRestaurantId) return;
    await _savePreferredRestaurant(picked);
  }

  bool _isSectionNow(_MealSection s) {
    if (!_isSelectedDateToday()) return false;
    final from = _parseClockToMinutes(s.hourFrom);
    final to = _parseClockToMinutes(s.hourTo);
    if (from == null || to == null) return false;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= from && nowMinutes < to;
  }

  List<_CourseGroup> _courseGroupsForSection(_MealSection section) {
    final grouped = <String, List<RestaurantMenuItem>>{};

    for (final item in section.items) {
      grouped.putIfAbsent(item.courseType, () => []).add(item);
    }

    final groups = grouped.entries.map((entry) {
      final items = List<RestaurantMenuItem>.from(entry.value)
        ..sort((a, b) {
          final itemCompare = a.itemSortOrder.compareTo(b.itemSortOrder);
          if (itemCompare != 0) return itemCompare;
          return a.foodName.compareTo(b.foodName);
        });

      final sortOrder = items
          .map((item) => item.courseSortOrder)
          .fold<int>(
            999,
            (minValue, value) => value < minValue ? value : minValue,
          );

      return _CourseGroup(title: entry.key, sortOrder: sortOrder, items: items);
    }).toList();

    groups.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.title.compareTo(b.title);
    });

    return groups;
  }

  bool get _showsMenu =>
      !_isBootstrapping &&
      _errorMessage == null &&
      _selectedRestaurantId != null;

  String get _title {
    if (_isBootstrapping || _errorMessage != null) return _l10n.universityMenus;
    if (_selectedRestaurantId == null) return _l10n.pickYourRestaurant;
    final selected = _restaurants.firstWhereOrNull(
      (r) => r.id == _selectedRestaurantId,
    );
    return selected?.title ?? _l10n.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    final showsMenu = _showsMenu;
    final reloadingBehind =
        _isLoadingMenu && _isDateInLoadedRange(_selectedDate);

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: showsMenu ? _onSwipe : null,
        child: CustomScrollView(
          slivers: [
            LargeTitleBar(
              title: _title,
              onTitleTap:
                  showsMenu && !_isSavingPreference && _restaurants.length > 1
                  ? _openRestaurantPickerSheet
                  : null,
              actions: [
                if (reloadingBehind || _isSavingPreference)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: CupertinoActivityIndicator(),
                  ),
                if (showsMenu && !_isSelectedDateToday())
                  BarTextButton(
                    label: _l10n.today,
                    onTap: () => _goToDate(DateTime.now()),
                  ),
              ],
              bottom: showsMenu
                  ? _WeekStrip(
                      selected: _selectedDate,
                      localeName: _localeName,
                      onSelect: _goToDate,
                      isEnabled: _canGoTo,
                    )
                  : null,
              bottomHeight: _WeekStrip.height,
            ),
            if (showsMenu)
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    _loadMenuForDate(_selectedDate, forceReload: true),
              ),
            ..._bodySlivers(),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    _changeDay(velocity < 0 ? 1 : -1);
  }

  List<Widget> _bodySlivers() {
    if (_isBootstrapping) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator(radius: 12)),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StatusView(
            icon: CupertinoIcons.wifi_exclamationmark,
            title: _errorMessage!,
            actionLabel: _l10n.tryAgain,
            onAction: _initialize,
          ),
        ),
      ];
    }

    if (_selectedRestaurantId == null) return [_restaurantList()];

    return [
      SliverToBoxAdapter(child: _menuBanner()),
      SliverToBoxAdapter(child: _dayContent()),
    ];
  }

  Widget _restaurantList() {
    final p = context.palette;

    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
          child: Text(
            _l10n.rememberRestaurant,
            style: AppText.subheadline.copyWith(color: p.secondaryLabel),
          ),
        ),
        GroupedSection(
          separatorInset: 58,
          children: [
            for (final restaurant in _restaurants)
              GroupedRow(
                leading: IconTile(icon: Icons.restaurant, color: p.accent),
                title: restaurant.title,
                subtitle: restaurant.subtitle,
                showChevron: !_isSavingPreference,
                onTap: _isSavingPreference
                    ? null
                    : () => _savePreferredRestaurant(restaurant.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _menuBanner() {
    if (_menuErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SavedDataBanner(
          title: _menuErrorMessage!,
          isError: true,
          onRetry: () => _loadMenuForDate(_selectedDate, forceReload: true),
        ),
      );
    }

    if (_menuFromCache && _isDateInLoadedRange(_selectedDate)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SavedDataBanner(
          title: _l10n.showingSavedMenu,
          fetchedAt: _menuFetchedAt,
          onRetry: _isLoadingMenu
              ? null
              : () => _loadMenuForDate(_selectedDate, forceReload: true),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// The selected day's meals. Changing day slides the new one in from the
  /// side the user moved towards; data arriving for the same day just updates
  /// in place.
  Widget _dayContent() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final key = ValueKey('${_selectedRestaurantId}_${_dateKey(_selectedDate)}');

    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == key;
        final dx = (incoming ? 1 : -1) * _direction * 0.12;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(dx, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: key, child: _dayBody()),
    );
  }

  Widget _dayBody() {
    final p = context.palette;
    final showsLoadedWeek = _isDateInLoadedRange(_selectedDate);
    final sections = showsLoadedWeek
        ? _mealSectionsForSelectedDate()
        : const <_MealSection>[];

    final Widget content;
    if (_isLoadingMenu && !showsLoadedWeek) {
      content = const SizedBox(
        height: 320,
        child: Center(child: CupertinoActivityIndicator(radius: 12)),
      );
    } else if (sections.isEmpty) {
      content = SizedBox(
        height: 360,
        child: StatusView(
          icon: Icons.no_meals_outlined,
          title: _l10n.noMenuForDay,
          message: _l10n.noMenuForDaySubtitle,
        ),
      );
    } else {
      content = Column(
        children: [
          for (final section in sections)
            _MealCard(
              section: section,
              groups: _courseGroupsForSection(section),
              isNow: _isSectionNow(section),
              servingNowLabel: _l10n.servingNow,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: Text(
            _daySubtitle(_selectedDate).toUpperCase(),
            style: figures(AppText.footnote).copyWith(color: p.secondaryLabel),
          ),
        ),
        content,
      ],
    );
  }
}

/// Monday to Sunday of the selected day's week. Today is tinted, the selected
/// day sits in a filled accent circle.
class _WeekStrip extends StatelessWidget {
  static const double height = 62;

  final DateTime selected;
  final String localeName;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime date) isEnabled;

  const _WeekStrip({
    required this.selected,
    required this.localeName,
    required this.onSelect,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = selected.subtract(
      Duration(days: selected.weekday - DateTime.monday),
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Builder(
              builder: (context) {
                final day = DateUtils.dateOnly(monday.add(Duration(days: i)));
                final isSelected = day == selected;
                final isToday = day == today;
                final enabled = isEnabled(day);
                final numberColor = isSelected
                    ? Colors.white
                    : (isToday ? p.accent : p.label);

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: DateFormat.MMMMEEEEd(localeName).format(day),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled ? () => onSelect(day) : null,
                      child: Opacity(
                        opacity: enabled ? 1 : 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.E(
                                localeName,
                              ).format(day).toUpperCase(),
                              style: AppText.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isToday ? p.accent : p.secondaryLabel,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: duration,
                              curve: Curves.easeOutCubic,
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? p.accent
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: figures(AppText.headline).copyWith(
                                  color: numberColor,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final _MealSection section;
  final List<_CourseGroup> groups;
  final bool isNow;
  final String servingNowLabel;

  const _MealCard({
    required this.section,
    required this.groups,
    required this.isNow,
    required this.servingNowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasHours =
        (section.hourFrom ?? '').isNotEmpty &&
        (section.hourTo ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: AppText.title3.copyWith(color: p.label),
                ),
              ),
              if (hasHours)
                Text(
                  '${section.hourFrom} – ${section.hourTo}',
                  style: figures(
                    AppText.subheadline,
                  ).copyWith(color: p.secondaryLabel),
                ),
            ],
          ),
          if (isNow) ...[
            const SizedBox(height: 6),
            _NowPill(label: servingNowLabel),
          ],
          const SizedBox(height: 10),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) Container(height: 0.5, color: p.separator),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groups[i].title,
                    style: AppText.footnote.copyWith(
                      color: p.secondaryLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final item in groups[i].items)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.foodName,
                        style: AppText.callout.copyWith(color: p.label),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NowPill extends StatelessWidget {
  final String label;

  const _NowPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.footnote.copyWith(
              color: p.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection {
  final String title;
  final int sortOrder;
  final String? hourFrom;
  final String? hourTo;
  final List<RestaurantMenuItem> items;

  const _MealSection({
    required this.title,
    required this.sortOrder,
    required this.hourFrom,
    required this.hourTo,
    required this.items,
  });
}

class _CourseGroup {
  final String title;
  final int sortOrder;
  final List<RestaurantMenuItem> items;

  const _CourseGroup({
    required this.title,
    required this.sortOrder,
    required this.items,
  });
}
