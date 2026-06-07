import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/app_models.dart';

class DemoService {
  DemoService._();

  static Future<User> simulateLogin() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return User(
      id: 'demo_user_001',
      name: 'Demo Customer',
      email: 'demo@hotdish.app',
      phone: '+94 77 123 4567',
      address: '123 Demo Road, Colombo',
    );
  }

  static Future<List<Product>> simulateMenu() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final raw = await rootBundle.loadString('assets/data/items.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CartItem>> simulateCart(List<Product> menu) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (menu.isEmpty) return [];
    return [
      CartItem(
        id: 'demo_cart_01',
        productId: menu.first.id,
        name: menu.first.name,
        price: menu.first.price,
        image: menu.first.image,
        quantity: 2,
      ),
    ];
  }

  static Future<bool> simulateCheckout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
