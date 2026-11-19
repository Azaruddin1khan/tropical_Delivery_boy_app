import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/delivery_order.dart';
import '../models/staff_user.dart';

class DeliveryApiService {
  static const List<String> _candidateBaseUrls = [
    'http://localhost:5001',
    'http://10.0.2.2:5001',
    'http://127.0.0.1:5001',
    'https://jennifer-manchester-robust-pleasant.trycloudflare.com',
  ];

  static String? _resolvedBaseUrl;

  /// Immediate synchronous fallback URL for widgets
  static String get fastBaseUrl => _resolvedBaseUrl ?? 'http://localhost:5001';

  /// Resolves the fastest working backend URL
  static Future<String> getBaseUrl() async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    for (final url in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$url/api/health');
        final response = await http
            .get(uri)
            .timeout(const Duration(milliseconds: 1200));
        if (response.statusCode == 200) {
          _resolvedBaseUrl = url;
          debugPrint('✅ DeliveryApiService connected to backend: $_resolvedBaseUrl');
          return url;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    _resolvedBaseUrl = 'http://localhost:5001';
    return _resolvedBaseUrl!;
  }

  // =========================================================================
  // 1. AUTHENTICATION & PROFILE
  // =========================================================================

  static Future<StaffUser?> login({
    required String username,
    required String password,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/auth/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': username.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['driver'] != null) {
          return StaffUser.fromJson(json['driver'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('DeliveryApiService.login error: $e');
    }
    return null;
  }

  static Future<bool> updateStatus({
    required String driverId,
    required String status,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/status');
      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'driverId': driverId, 'status': status}),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double speedKmh = 0,
    double headingDeg = 0,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/location');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'driverId': driverId,
              'latitude': latitude,
              'longitude': longitude,
              'speedKmh': speedKmh,
              'headingDeg': headingDeg,
            }),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 2. ORDERS MANAGEMENT
  // =========================================================================

  static Future<List<DeliveryOrder>> fetchAssignedOrders(String driverId) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/assigned?driverId=$driverId');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('DeliveryApiService.fetchAssignedOrders error: $e');
    }
    return [];
  }

  static Future<List<DeliveryOrder>> fetchDeliveryHistory(String driverId) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/history?driverId=$driverId');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('DeliveryApiService.fetchDeliveryHistory error: $e');
    }
    return [];
  }

  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? driverId,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/$orderId/status');
      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status, 'driverId': driverId}),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeliveryApiService.updateOrderStatus error: $e');
      return false;
    }
  }

  static Future<bool> markCashCollected({
    required String orderId,
    required double amount,
    String? driverId,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/$orderId/cash-collected');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'amount': amount, 'driverId': driverId}),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeliveryApiService.markCashCollected error: $e');
      return false;
    }
  }

  static Future<DeliveryOrder?> verifyCode(String code) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/verify-code');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code.trim()}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['order'] != null) {
          return DeliveryOrder.fromJson(json['order'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('DeliveryApiService.verifyCode error: $e');
    }
    return null;
  }
}
