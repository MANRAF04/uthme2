import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/restaurant.dart';
import '../models/restaurant_menu.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/saved_data_banner.dart';

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
    final selected = preferredRestaurantId != null &&
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
      await _storage.write(
        key: _legacyPreferredKey,
        value: restaurantId,
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.preferenceSyncFailed(e))),
        );
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
    return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadMenuForDate(DateTime date, {bool forceReload = false}) async {
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

  Future<void> _changeDay(int offset) async {
    await _loadMenuForDate(_dateAtOffset(offset));
  }

  DateTime _dateAtOffset(int offset) =>
      DateUtils.dateOnly(_selectedDate.add(Duration(days: offset)));

  /// While a reload is in flight only moves inside the loaded week are allowed,
  /// so two fetches can never race to fill the same screen.
  bool _canChangeDay(int offset) =>
      !_isLoadingMenu || _isDateInLoadedRange(_dateAtOffset(offset));

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

      final isCurrent = currentMinutes >= fromMinutes && currentMinutes < toMinutes;
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

    final activeWindows = _mealTypes.where((window) => window.isActive).toList();
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
          title: (window?.title.isNotEmpty ?? false) ? window!.title : sample.mealType,
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
        return [
          ...sections.sublist(pivot),
          ...sections.sublist(0, pivot),
        ];
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
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: _restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = _restaurants[index];
              final isSelected = restaurant.id == _selectedRestaurantId;

              return ListTile(
                title: Text(restaurant.title),
                subtitle: Text(restaurant.subtitle),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, restaurant.id),
              );
            },
          ),
        );
      },
    );

    if (picked == null || picked == _selectedRestaurantId) return;
    await _savePreferredRestaurant(picked);
  }

  // Read-only helper - no state mutation.
  bool _isSectionNow(_MealSection s) {
    if (!_isSelectedDateToday()) return false;
    final from = _parseClockToMinutes(s.hourFrom);
    final to = _parseClockToMinutes(s.hourTo);
    if (from == null || to == null) return false;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= from && nowMinutes < to;
  }

  Widget _buildInitialRestaurantPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.pickYourRestaurant,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _l10n.rememberRestaurant,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _restaurants.length,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final restaurant = _restaurants[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: AppColors.coralDeep),
                  ),
                  title: Text(
                    restaurant.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    restaurant.subtitle,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: _isSavingPreference
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  onTap: _isSavingPreference ? null : () => _savePreferredRestaurant(restaurant.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedRestaurant =
        _restaurants.firstWhereOrNull((restaurant) => restaurant.id == _selectedRestaurantId);
    final showsLoadedWeek = _isDateInLoadedRange(_selectedDate);
    final mealSections =
        showsLoadedWeek ? _mealSectionsForSelectedDate() : const <_MealSection>[];

    return Column(
      children: [
        // Restaurant header with teal gradient.
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.tealGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRestaurant?.title ?? _l10n.restaurant,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedRestaurant?.subtitle ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _isSavingPreference ? null : _openRestaurantPickerSheet,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _l10n.change,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Day picker.
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _DayArrowButton(
                icon: Icons.chevron_left,
                onTap: _canChangeDay(-1) ? () => _changeDay(-1) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _dayTitle(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _daySubtitle(_selectedDate),
                      style: monoStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _DayArrowButton(
                icon: Icons.chevron_right,
                onTap: _canChangeDay(1) ? () => _changeDay(1) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Menu error banner.
        if (_menuErrorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.30)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.coralDeep),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _menuErrorMessage!,
                      style: const TextStyle(color: AppColors.coralDeep),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _loadMenuForDate(_selectedDate, forceReload: true),
                    child: Text(_l10n.retry),
                  ),
                ],
              ),
            ),
          )
        else if (_menuFromCache && showsLoadedWeek)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SavedDataBanner(
              title: _l10n.showingSavedMenu,
              fetchedAt: _menuFetchedAt,
              onRetry: _isLoadingMenu
                  ? null
                  : () => _loadMenuForDate(_selectedDate, forceReload: true),
            ),
          ),
        Expanded(
          child: _isLoadingMenu && !showsLoadedWeek
              ? const Center(child: CircularProgressIndicator())
              : mealSections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.no_meals_outlined,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _l10n.noMenuForDay,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _l10n.noMenuForDaySubtitle,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildGroupedMenu(mealSections),
        ),
      ],
    );
  }

  Widget _buildGroupedMenu(List<_MealSection> sections) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final courseGroups = _courseGroupsForSection(section);
        final now = _isSectionNow(section);
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: now
                  ? AppColors.coral.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header row.
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 16,
                        color: AppColors.coralDeep,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (now)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        child: Text(
                          _l10n.servingNow,
                          style: monoStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      )
                    else if ((section.hourFrom ?? '').isNotEmpty &&
                        (section.hourTo ?? '').isNotEmpty)
                      Text(
                        '${section.hourFrom} – ${section.hourTo}',
                        style: monoStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Course groups.
                ...courseGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title.toUpperCase(),
                          style: monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDeep,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        ...group.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    item.foodName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          .fold<int>(999, (minValue, value) => value < minValue ? value : minValue);

      return _CourseGroup(
        title: entry.key,
        sortOrder: sortOrder,
        items: items,
      );
    }).toList();

    groups.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.title.compareTo(b.title);
    });

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isBootstrapping) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.coralDeep, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _initialize,
                    child: Text(_l10n.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (_selectedRestaurantId == null) {
      body = _buildInitialRestaurantPicker();
    } else {
      body = _buildMenuContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.universityMenus),
        actions: [
          IconButton(
            tooltip: _l10n.refresh,
            onPressed: _selectedRestaurantId == null || _isLoadingMenu
                ? null
                : () => _loadMenuForDate(_selectedDate, forceReload: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        // The saved week is already on screen; the reload runs behind it.
        bottom: _isLoadingMenu && _isDateInLoadedRange(_selectedDate)
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: SafeArea(child: body),
    );
  }
}

class _DayArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _DayArrowButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.38 : 1.0,
        child: Container(
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: colorScheme.onSurface,
          ),
        ),
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
