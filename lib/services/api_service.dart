import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/delivery_order.dart';
import '../models/staff_user.dart';

class DeliveryAuthResult {
  final bool success;
  final StaffUser? user;
  final String? error;

  const DeliveryAuthResult({
    required this.success,
    this.user,
    this.error,
  });
}

class OrderVerifyResult {
  final DeliveryOrder? order;
  final bool isAssignedToOther;
  final bool isUnassigned;
  final String? assignedDriverName;
  final String? errorMessage;

  const OrderVerifyResult({
    this.order,
    this.isAssignedToOther = false,
    this.isUnassigned = false,
    this.assignedDriverName,
    this.errorMessage,
  });
}

class DeliveryApiService {
  static const String liveCloudBaseUrl = 'https://tropical-admin-six.vercel.app';
  static String? _resolvedBaseUrl;

  /// Immediate synchronous fallback URL for widgets
  static String get fastBaseUrl => _resolvedBaseUrl ?? liveCloudBaseUrl;

  /// Resolves the fastest working backend URL
  static Future<String> getBaseUrl() async {
    return liveCloudBaseUrl;
  }

  // =========================================================================
  // 1. AUTHENTICATION & PROFILE
  // =========================================================================

  static Future<DeliveryAuthResult> login({
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
            body: jsonEncode({'email': username.trim(), 'password': password.trim()}),
          )
          .timeout(const Duration(seconds: 8));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && json['success'] == true && json['driver'] != null) {
        return DeliveryAuthResult(
          success: true,
          user: StaffUser.fromJson(json['driver'] as Map<String, dynamic>),
        );
      } else {
        return DeliveryAuthResult(
          success: false,
          error: json['error']?.toString() ?? 'Incorrect courier email or password.',
        );
      }
    } catch (e) {
      debugPrint('DeliveryApiService.login error: $e');
      return const DeliveryAuthResult(
        success: false,
        error: 'Unable to connect to server. Please check your internet connection.',
      );
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/auth/forgot-password');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('DeliveryApiService.forgotPassword error: $e');
      return {
        'success': false,
        'error': 'Unable to connect to server. Please check your internet connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/auth/verify-otp');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'otp': otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('DeliveryApiService.verifyOtp error: $e');
      return {
        'success': false,
        'error': 'Unable to connect to server. Please check your internet connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    String? token,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/auth/reset-password');
      final payload = <String, dynamic>{
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword.trim(),
      };
      if (token != null) payload['token'] = token;

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('DeliveryApiService.resetPassword error: $e');
      return {
        'success': false,
        'error': 'Unable to connect to server. Please check your internet connection.',
      };
    }
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
    String? paymentCollectedMethod,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/$orderId/status');
      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': status,
              'driverId': driverId,
              'paymentCollectedMethod': ?paymentCollectedMethod,
            }),
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
    String paymentMethod = 'cash',
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/$orderId/cash-collected');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'driverId': driverId,
              'paymentCollectedMethod': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeliveryApiService.markCashCollected error: $e');
      return false;
    }
  }

  static Future<OrderVerifyResult> verifyCodeResult(String code, {String? driverId}) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/delivery-boy/orders/verify-code');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code.trim(),
              'driverId': ?driverId,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && json['success'] == true && json['order'] != null) {
        return OrderVerifyResult(
          order: DeliveryOrder.fromJson(json['order'] as Map<String, dynamic>),
        );
      } else if (response.statusCode == 403) {
        final errorCode = json['code'] as String? ?? '';
        final driverName = json['assignedDriverName'] as String?;
        final errMsg = json['error'] as String? ?? 'Not allowed';
        return OrderVerifyResult(
          isAssignedToOther: errorCode == 'ASSIGNED_TO_OTHER',
          isUnassigned: errorCode == 'UNASSIGNED',
          assignedDriverName: driverName,
          errorMessage: errMsg,
        );
      }
    } catch (e) {
      debugPrint('DeliveryApiService.verifyCodeResult error: $e');
    }
    return const OrderVerifyResult();
  }

  static Future<DeliveryOrder?> verifyCode(String code, {String? driverId}) async {
    final res = await verifyCodeResult(code, driverId: driverId);
    return res.order;
  }
}
