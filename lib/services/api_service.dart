import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grade.dart';
import '../models/restaurant.dart';
import '../models/restaurant_menu.dart';

class TaskCompletedException implements Exception {}

class ApiService {
  static const String baseUrl = "https://manraf.duckdns.org:4242/api";
  static const Duration _pollInterval = Duration(milliseconds: 2500);
  static const Duration _pollTimeout = Duration(minutes: 2);
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<List<Grade>> fetchGrades(String username, String password, {bool forceRefresh = false}) async {
    final response = await _timed(
      http.post(
        Uri.parse('$baseUrl/get-grades'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "force_refresh": forceRefresh,
        }),
      ),
    );

    if (response.statusCode != 200) {
      String message = "Failed to authenticate with server";
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['detail'] != null) {
          message = data['detail'].toString();
        }
      } catch (_) {
        // Fall back to the generic message.
      }
      throw Exception(message);
    }

    final data = jsonDecode(response.body);

    if (data['status'] == 'success') {
      return (data['data'] as List).map((item) => Grade.fromJson(item)).toList();
    } else if (data['status'] == 'processing') {
      return await _pollTaskStatus(data['task_id']);
    }
    throw Exception("Unknown API response");
  }

  Future<List<UniversityRestaurant>> fetchRestaurants() async {
    final response = await _timed(http.get(Uri.parse('$baseUrl/restaurants')));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response.body, fallback: 'Failed to fetch restaurants.'),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(UniversityRestaurant.fromJson)
        .toList();
  }

  Future<RestaurantMenuRange> fetchRestaurantMenu(
    String restaurantId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse('$baseUrl/restaurants/$restaurantId/menu').replace(
      queryParameters: {
        'start': _formatDate(startDate),
        'end': _formatDate(endDate),
      },
    );

    final response = await _timed(http.get(uri));
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response.body, fallback: 'Failed to fetch restaurant menu.'),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return RestaurantMenuRange.fromJson(data);
  }

  Future<void> savePreferredRestaurant({
    required String username,
    required String password,
    required String restaurantId,
  }) async {
    final response = await _timed(
      http.post(
        Uri.parse('$baseUrl/user/preference'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': username,
          'password': password,
          'restaurant_id': restaurantId,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response.body, fallback: 'Failed to save preferred restaurant.'),
      );
    }
  }

  Future<List<Grade>> _pollTaskStatus(String taskId) async {
    final deadline = DateTime.now().add(_pollTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_pollInterval);

      final response =
          await _timed(http.get(Uri.parse('$baseUrl/task-status/$taskId')));
      if (response.statusCode != 200) {
        throw Exception('Task status request failed (${response.statusCode}).');
      }

      final data = jsonDecode(response.body);
      final status = data['status']?.toString();

      if (status == 'completed') {
        throw TaskCompletedException();
      } else if (status == 'failed') {
        throw Exception("VPN Scrape Failed: ${data['message']}");
      } else if (status == 'processing') {
        continue;
      }

      throw Exception('Unexpected task status: $status');
    }

    throw Exception('Timed out while fetching grades. Please try again.');
  }

  /// Hard ceiling on every request: a server that accepts the connection and
  /// then hangs must fail fast, so callers can fall back to their cached copy.
  Future<http.Response> _timed(Future<http.Response> request) {
    return request.timeout(
      _requestTimeout,
      onTimeout: () => throw Exception('The server took too long to respond.'),
    );
  }

  String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _extractErrorMessage(String rawBody, {required String fallback}) {
    try {
      final data = jsonDecode(rawBody);
      if (data is Map<String, dynamic> && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {
      // Keep fallback when body is not JSON.
    }
    return fallback;
  }
}