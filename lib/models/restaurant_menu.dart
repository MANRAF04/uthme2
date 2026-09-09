class RestaurantMenuItem {
  final String id;
  final DateTime date;
  final String mealTypeId;
  final String mealType;
  final int mealTypeSortOrder;
  final String? mealHourFrom;
  final String? mealHourTo;
  final String courseType;
  final int courseSortOrder;
  final int itemSortOrder;
  final String foodName;

  const RestaurantMenuItem({
    required this.id,
    required this.date,
    required this.mealTypeId,
    required this.mealType,
    required this.mealTypeSortOrder,
    required this.mealHourFrom,
    required this.mealHourTo,
    required this.courseType,
    required this.courseSortOrder,
    required this.itemSortOrder,
    required this.foodName,
  });

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItem(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      mealTypeId: json['meal_type_id']?.toString() ?? '',
      mealType: json['meal_type']?.toString() ?? 'Meal',
      mealTypeSortOrder: (json['meal_type_sort_order'] as num?)?.toInt() ?? 999,
      mealHourFrom: json['meal_hour_from']?.toString(),
      mealHourTo: json['meal_hour_to']?.toString(),
      courseType: json['course_type']?.toString() ?? 'Dish',
      courseSortOrder: (json['course_sort_order'] as num?)?.toInt() ?? 999,
      itemSortOrder: (json['item_sort_order'] as num?)?.toInt() ?? 999,
      foodName: json['food_name']?.toString() ?? 'Unknown food',
    );
  }
}

class MealTypeWindow {
  final String id;
  final String mealTypeId;
  final String title;
  final int sortOrder;
  final String? hourFrom;
  final String? hourTo;
  final bool isActive;

  const MealTypeWindow({
    required this.id,
    required this.mealTypeId,
    required this.title,
    required this.sortOrder,
    required this.hourFrom,
    required this.hourTo,
    required this.isActive,
  });

  factory MealTypeWindow.fromJson(Map<String, dynamic> json) {
    return MealTypeWindow(
      id: json['id']?.toString() ?? '',
      mealTypeId: json['meal_type_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Meal',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 999,
      hourFrom: json['hour_from']?.toString(),
      hourTo: json['hour_to']?.toString(),
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
    );
  }
}

class RestaurantMenuRange {
  final DateTime startDate;
  final DateTime endDate;
  final List<MealTypeWindow> mealTypes;
  final List<RestaurantMenuItem> items;

  const RestaurantMenuRange({
    required this.startDate,
    required this.endDate,
    required this.mealTypes,
    required this.items,
  });

  factory RestaurantMenuRange.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final range = (json['range'] as Map<String, dynamic>?) ?? const {};
    final mealTypesJson = (json['meal_types'] as List<dynamic>?) ?? const [];
    final itemsJson = (json['data'] as List<dynamic>?) ?? const [];

    return RestaurantMenuRange(
      startDate: DateTime.tryParse(range['start']?.toString() ?? '') ?? now,
      endDate: DateTime.tryParse(range['end']?.toString() ?? '') ?? now,
      mealTypes: mealTypesJson
          .whereType<Map<String, dynamic>>()
          .map(MealTypeWindow.fromJson)
          .toList(),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(RestaurantMenuItem.fromJson)
          .toList(),
    );
  }
}