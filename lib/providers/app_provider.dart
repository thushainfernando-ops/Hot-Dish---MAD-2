import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

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
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get total => subtotal + 250; // Assuming fixed delivery fee of Rs. 250

  // Auth Methods
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _apiService.login(email, password);
      // Assuming result contains user data or token.
      if (result['success'] == true || result['status'] == 'success') {
        // Parse user from result or fetch profile
        final userId =
            result['user_id']?.toString() ?? result['id']?.toString();
        if (userId != null) {
          await _apiService.saveToken(
            userId,
          ); // store user ID as 'token' for simplicity
          await fetchProfile();
          return true;
        }
      }
      _errorMessage = result['message'] ?? 'Login failed';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      await fetchProfile();
      return true;
    }
    return false;
  }

  Future<void> fetchProfile() async {
    final userId = await _apiService.getToken();
    if (userId != null) {
      _currentUser = await _apiService.getProfile(userId);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final userId = await _apiService.getToken();
    if (userId != null) {
      await _apiService.logout(userId);
    }
    _currentUser = null;
    _cartItems = [];
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
      final fetched = await _apiService.getCart(_currentUser!.id);

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
      final success = await _apiService.addToCart(
        _currentUser!.id,
        product.id,
        quantity,
      );
      if (success) {
        await fetchCart(); // Refresh cart
        return true;
      }
      return false;
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
          await _apiService.updateCart(_cartItems[itemIndex].id, newQuantity);
        } catch (_) {
          // ignore sync errors for now; local UI state preserved
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
          await _apiService.removeFromCart(removed.id);
        } catch (_) {
          // ignore sync errors; local UI state preserved
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
        _cartItems = []; // Clear local cart
        notifyListeners();
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
