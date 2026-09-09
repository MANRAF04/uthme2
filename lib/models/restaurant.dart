class UniversityRestaurant {
  final String id;
  final String title;
  final String city;

  const UniversityRestaurant({
    required this.id,
    required this.title,
    required this.city,
  });

  String get subtitle => city.isEmpty ? 'Campus restaurant' : city;

  factory UniversityRestaurant.fromJson(Map<String, dynamic> json) {
    return UniversityRestaurant(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Restaurant',
      city: json['city']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'city': city,
      };
}