import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/realtime_database_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  List<Product> _menuItems = [];
  int _selectedIndex = 0;
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  List<Product> get menuItems => _menuItems;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedIndex => _selectedIndex;

  double get subtotal =>
      _cartItems.fold(0, (acc, item) => acc + (item.price * item.quantity));
  double get total => subtotal + 250; // Assuming fixed delivery fee of Rs. 250

  StreamSubscription? _cartSubscription;

  void _cancelCartSubscription() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  String _normalizeImage(String img) {
    final s = img.toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http')) return s;
    if (s.startsWith('assets/')) return s;
    return 'assets/$s';
  }

  void _subscribeToRealtimeCart(String uid) {
    _cancelCartSubscription();
    _cartSubscription = RealtimeDatabaseService.cartStream(uid).listen((items) {
      _cartItems =
          items
              .map(
                (c) => CartItem(
                  id: c.id,
                  productId: c.productId,
                  name: c.name,
                  price: c.price,
                  image: _normalizeImage(c.image),
                  quantity: c.quantity,
                ),
              )
              .toList();
      notifyListeners();
    }, onError: (_) {});
  }

  // Auth Methods
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final cred = await fb_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      final fbUser = cred.user;
      if (fbUser != null) {
        await fetchProfile(uid: fbUser.uid);
        return true;
      }
      _errorMessage = 'Authentication failed';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkLoginStatus() async {
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      await fetchProfile(uid: fbUser.uid);
      return true;
    }
    return false;
  }

  Future<void> fetchProfile({String? uid}) async {
    final userId = uid ?? fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    _setLoading(true);
    try {
      final profile = await RealtimeDatabaseService.getUserProfile(userId);
      if (profile != null) {
        _currentUser = profile;
        notifyListeners();
      } else {
        // Try to fetch via API as a fallback
        final apiProfile = await _apiService.getProfile(userId);
        if (apiProfile != null) {
          _currentUser = apiProfile;
          notifyListeners();
        } else {
          // If DB and API both fail, fallback to Firebase Auth data so the profile screen
          // still displays basic logged-in user information.
          final authUser = fb_auth.FirebaseAuth.instance.currentUser;
          if (authUser != null) {
            _currentUser = User(
              id: userId,
              name: authUser.displayName ?? 'User',
              email: authUser.email ?? 'Unknown',
              phone: '',
              address: '',
            );
            notifyListeners();
          }
        }
      }
      if (_currentUser != null) {
        await fetchCart();
        _subscribeToRealtimeCart(userId);
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      final userId = await _apiService.getToken();
      if (userId != null) await _apiService.logout(userId);
    } catch (_) {}
    _currentUser = null;
    _cartItems = [];
    _cancelCartSubscription();
    notifyListeners();
  }

  // Menu Methods
  Future<void> fetchMenu() async {
    _setLoading(true);
    try {
      final fetched = await _apiService.getMenu();
      // Normalize image paths: if server returns only a filename, map to local assets folder
      String normalizeImage(String img) {
        final s = img.toString().trim();
        if (s.isEmpty) return '';
        if (s.startsWith('http')) return s;
        if (s.startsWith('assets/')) return s;
        return 'assets/$s';
      }

      _menuItems =
          fetched
              .map(
                (p) => Product(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  price: p.price,
                  image: normalizeImage(p.image),
                  category: p.category,
                ),
              )
              .toList();
      if (_menuItems.isEmpty) throw Exception('Empty menu');
    } catch (e) {
      _errorMessage = 'Failed to load menu: \$e';
      // On failure leave _menuItems empty so UI shows appropriate message
    } finally {
      _setLoading(false);
    }
  }

  // Cart Methods
  Future<void> fetchCart() async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      // Try Realtime Database first for real-time cart
      List<CartItem> fetched = [];
      try {
        fetched = await RealtimeDatabaseService.getCart(_currentUser!.id);
      } catch (_) {
        // fallback to API if realtime DB not available
        fetched = await _apiService.getCart(_currentUser!.id);
      }

      String normalizeImage(String img) {
        final s = img.toString().trim();
        if (s.isEmpty) return '';
        if (s.startsWith('http')) return s;
        if (s.startsWith('assets/')) return s;
        return 'assets/$s';
      }

      // Re-create CartItem objects with normalized image paths so UI
      // consistently shows images whether they are remote URLs or local
      // assets.
      _cartItems =
          fetched
              .map(
                (c) => CartItem(
                  id: c.id,
                  productId: c.productId,
                  name: c.name,
                  price: c.price,
                  image: normalizeImage(c.image),
                  quantity: c.quantity,
                ),
              )
              .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to load cart";
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addToCart(Product product, int quantity) async {
    if (_currentUser == null) return false;
    try {
      // Update local cart immediately
      final existing = _cartItems.indexWhere((i) => i.productId == product.id);
      if (existing != -1) {
        _cartItems[existing].quantity += quantity;
      } else {
        final newItem = CartItem(
          id: product.id.toString(),
          productId: product.id.toString(),
          name: product.name,
          price: product.price,
          image: product.image,
          quantity: quantity,
        );
        _cartItems.add(newItem);
      }
      notifyListeners();

      // Sync to Realtime Database; fallback to API if needed
      try {
        // save individual item (uses product.id as key)
        final item = _cartItems.firstWhere((i) => i.productId == product.id);
        await RealtimeDatabaseService.setCartItem(_currentUser!.id, item);
      } catch (_) {
        try {
          await _apiService.addToCart(_currentUser!.id, product.id, quantity);
          // refresh from API
          await fetchCart();
        } catch (_) {}
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCartQuantity(String cartItemId, int newQuantity) async {
    try {
      // Update local cart item first so UI responds immediately
      final itemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (itemIndex == -1) return false;

      _cartItems[itemIndex].quantity = newQuantity;
      notifyListeners();

      // If logged in, attempt to sync with backend using update endpoint
      if (_currentUser != null) {
        try {
          // try realtime db first
          await RealtimeDatabaseService.setCartItem(
            _currentUser!.id,
            _cartItems[itemIndex],
          );
        } catch (_) {
          try {
            await _apiService.updateCart(_cartItems[itemIndex].id, newQuantity);
          } catch (_) {
            // ignore sync errors for now; local UI state preserved
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromCart(String cartItemId) async {
    try {
      // Remove from local cart first so UI responds immediately
      final idx = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (idx == -1) return false;
      final removed = _cartItems[idx];

      _cartItems.removeAt(idx);
      notifyListeners();

      // If logged in, attempt to sync removal with backend
      if (_currentUser != null) {
        try {
          await RealtimeDatabaseService.removeCartItem(
            _currentUser!.id,
            removed.id,
          );
        } catch (_) {
          try {
            await _apiService.removeFromCart(removed.id);
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> placeOrder(Map<String, String> paymentDetails) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      final success = await _apiService.checkout(
        _currentUser!.id,
        paymentDetails,
      );
      if (success) {
        // Prepare order payload
        final orderItems =
            _cartItems
                .map(
                  (c) => {
                    'id': c.id,
                    'name': c.name,
                    'quantity': c.quantity,
                    'price': c.price,
                  },
                )
                .toList();

        final orderData = {
          'items': orderItems,
          'total': subtotal,
          'status': 'pending',
          'payment': paymentDetails,
          'delivery_address': _currentUser?.address ?? '',
        };

        // Attempt to create order on backend (best-effort)
        try {
          final apiResult = await _apiService.createOrder(
            _currentUser!.id,
            orderData,
          );
          if (apiResult != null && apiResult.containsKey('order_id')) {
            orderData['server_order_id'] = apiResult['order_id'].toString();
          }
        } catch (_) {}

        // Save order to Realtime Database for user's history
        try {
          await RealtimeDatabaseService.saveOrder(_currentUser!.id, orderData);
        } catch (_) {}

        // Clear local cart and attempt to clear backend copies (Realtime DB + API fallback)
        final previousIds = _cartItems.map((e) => e.id).toList();
        _cartItems = [];
        notifyListeners();
        try {
          await RealtimeDatabaseService.clearCart(_currentUser!.id);
        } catch (_) {}
        // Try to remove items via API as a best-effort fallback
        for (final id in previousIds) {
          try {
            await _apiService.removeFromCart(id);
          } catch (_) {}
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Allow navigation between main pages (used by HomeScreen "Order Now")
  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
