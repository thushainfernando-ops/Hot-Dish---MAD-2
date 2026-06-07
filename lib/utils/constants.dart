import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primaryOrange = Color(0xFFE86A1F); // Darker orange
  static const Color darkBlue = Color(0xFF051D54); // Much darker blue
  static const Color darkBlue2 = Color(0xFF0D2A6B); // Much darker blue
  static const Color darkBlue3 = Color(0xFF0F3589); // Much darker blue variant
  static const Color background = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
}

class AppConstants {
  AppConstants._();

  // Dynamic Base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/MAD%201%20Mobile%20App/api';
    } else {
      // Android Emulator IP for localhost
      return 'http://10.0.2.2/MAD%201%20Mobile%20App/api';
    }
  }

  // API Endpoints - Using actual website PHP files
  static String get endpointLogin => '$baseUrl/login.php';
  static String get endpointRegister => '$baseUrl/register.php';
  static String get endpointMenu => '$baseUrl/menu.php';
  static String get endpointAddToCart => '$baseUrl/add_to_cart.php';
  static String get endpointCart => '$baseUrl/cart.php';
  static String get endpointPayment => '$baseUrl/payment.php';
  static String get endpointProfile => '$baseUrl/profile.php';
  static String get endpointLogout => '$baseUrl/logout.php';
  static String get endpointUpdateCart => '$baseUrl/update_cart.php';
  static String get endpointRemoveFromCart => '$baseUrl/remove_from_cart.php';
  static String get endpointContact => '$baseUrl/contact.php';
  static String get endpointOrders => '$baseUrl/orders.php';
}
