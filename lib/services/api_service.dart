import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../utils/constants.dart';

class ApiService {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      'user_token',
    ); // Or just user_id depending on backend
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
  }

  // Generic POST request
  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final client = http.Client();
      final request = http.Request('POST', Uri.parse(url));
      // Convert all values to strings for bodyFields
      request.bodyFields = body.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Generic GET request
  Future<dynamic> get(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Specific API calls

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await post(AppConstants.endpointLogin, {
      'email': email,
      'password': password,
    });
    return result;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String address,
    String password,
  ) async {
    return await post(AppConstants.endpointRegister, {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'password': password,
    });
  }

  Future<List<Product>> getMenu() async {
    final result = await get(AppConstants.endpointMenu);
    if (result is List) {
      return result.map((json) => Product.fromJson(json)).toList();
    } else if (result is Map && result.containsKey('data')) {
      // Handle wrapper format if exists
      return (result['data'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<bool> addToCart(String userId, String productId, int quantity) async {
    final result = await post(AppConstants.endpointAddToCart, {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity.toString(),
    });
    return result['success'] == true || result['status'] == 'success';
  }

  Future<bool> updateCart(String cartId, int quantity) async {
    final result = await post(AppConstants.endpointUpdateCart, {
      'cart_id': cartId,
      'quantity': quantity.toString(),
    });
    return result['success'] == true || result['status'] == 'success';
  }

  Future<bool> removeFromCart(String cartId) async {
    final result = await post(AppConstants.endpointRemoveFromCart, {
      'cart_id': cartId,
    });
    return result['success'] == true || result['status'] == 'success';
  }

  Future<List<CartItem>> getCart(String userId) async {
    final result = await post(AppConstants.endpointCart, {'user_id': userId});
    if (result is List) {
      return result.map((json) => CartItem.fromJson(json)).toList();
    } else if (result is Map && result.containsKey('cart_items')) {
      return (result['cart_items'] as List)
          .map((json) => CartItem.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<bool> checkout(
    String userId,
    Map<String, String> paymentDetails,
  ) async {
    final body = {'user_id': userId, ...paymentDetails};
    final result = await post(AppConstants.endpointPayment, body);
    return result['success'] == true || result['status'] == 'success';
  }

  Future<User?> getProfile(String userId) async {
    final result = await post(AppConstants.endpointProfile, {
      'user_id': userId,
    });
    if (result != null &&
        (result['success'] == true ||
            result['status'] == 'success' ||
            result.containsKey('name'))) {
      return User.fromJson(result);
    }
    return null;
  }

  Future<bool> logout(String userId) async {
    await post(AppConstants.endpointLogout, {'user_id': userId});
    await clearToken();
    return true;
  }

  Future<bool> sendContactMessage({
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String message,
  }) async {
    final result = await post(AppConstants.endpointContact, {
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'message': message,
    });

    return result['success'] == true || result['status'] == 'success';
  }

  Future<List<dynamic>> getOrders(String userId) async {
    try {
      final result = await post(AppConstants.endpointOrders, {
        'user_id': userId,
      });
      if (result is List) return result;
      if (result is Map && result.containsKey('orders'))
        return result['orders'] as List<dynamic>;
      // If wrapper contains data
      if (result is Map && result.containsKey('data'))
        return result['data'] as List<dynamic>;
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createOrder(
    String userId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final payload = {'user_id': userId, ...orderData};
      final result = await post(AppConstants.endpointOrders, payload);
      if (result is Map<String, dynamic>) return result;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateOrder(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final payload = {'order_id': orderId, ...orderData};
      final result = await post(AppConstants.endpointOrders, payload);
      if (result is Map) {
        return result['success'] == true || result['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
