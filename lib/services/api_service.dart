import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site.dart';
import '../models/order.dart';
import '../models/lead.dart';

class ApiService {
  final Site site;

  ApiService(this.site);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': site.apiKey,
  };

  // Authentication
  Future<Map<String, dynamic>?> authenticate() async {
    try {
      final response = await http.post(
        Uri.parse('${site.apiUrl}/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': site.apiKey}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }

  // Statistics
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('${site.apiUrl}/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Stats error: $e');
      return null;
    }
  }

  // Orders
  Future<List<Order>> getOrders({
    int page = 1,
    int perPage = 20,
    String status = 'any',
  }) async {
    try {
      final uri = Uri.parse('${site.apiUrl}/orders').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (status != 'any') 'status': status,
        },
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = (data['orders'] as List)
            .map((o) => Order.fromJson(o))
            .toList();
        return orders;
      }
      return [];
    } catch (e) {
      print('Orders error: $e');
      return [];
    }
  }

  Future<Order?> getOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${site.apiUrl}/orders/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Order error: $e');
      return null;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${site.apiUrl}/orders/$orderId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update order error: $e');
      return false;
    }
  }

  // Leads
  Future<List<Lead>> getLeads({
    int page = 1,
    int perPage = 20,
    String status = 'all',
  }) async {
    try {
      final uri = Uri.parse('${site.apiUrl}/leads').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (status != 'all') 'status': status,
        },
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leads = (data['leads'] as List)
            .map((l) => Lead.fromJson(l))
            .toList();
        return leads;
      }
      return [];
    } catch (e) {
      print('Leads error: $e');
      return [];
    }
  }

  Future<Lead?> getLead(int leadId) async {
    try {
      final response = await http.get(
        Uri.parse('${site.apiUrl}/leads/$leadId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Lead.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Lead error: $e');
      return null;
    }
  }

  Future<bool> updateLeadStatus(int leadId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${site.apiUrl}/leads/$leadId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update lead error: $e');
      return false;
    }
  }

  // Device Registration
  Future<bool> registerDevice(String deviceToken, String deviceName) async {
    try {
      final response = await http.post(
        Uri.parse('${site.apiUrl}/register-device'),
        headers: _headers,
        body: jsonEncode({
          'device_token': deviceToken,
          'device_name': deviceName,
          'platform': 'android',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Register device error: $e');
      return false;
    }
  }

  Future<bool> unregisterDevice(String deviceToken) async {
    try {
      final response = await http.delete(
        Uri.parse('${site.apiUrl}/unregister-device'),
        headers: _headers,
        body: jsonEncode({'device_token': deviceToken}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Unregister device error: $e');
      return false;
    }
  }
}
