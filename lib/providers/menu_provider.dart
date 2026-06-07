import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';

final menuProvider =
    StateNotifierProvider<MenuNotifier, AsyncValue<List<Product>>>(
      (ref) => MenuNotifier(),
    );

class MenuNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  MenuNotifier() : super(const AsyncLoading()) {
    loadMenu();
  }

  static const String cacheKey = 'menu_cache';

  Future<List<Product>> _loadAssetMenu() async {
    debugPrint('Loading local JSON...');
    final raw = await rootBundle.loadString('assets/data/items.json');
    final data = jsonDecode(raw) as List<dynamic>;
    final products =
        data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    debugPrint('Loaded ${products.length} items from JSON');
    return products;
  }

  Future<List<Product>> _loadCachedMenu(String jsonString) async {
    final data = jsonDecode(jsonString) as List<dynamic>;
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> loadMenu() async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    List<Product> initialMenu = [];
    String loadMessage = 'Loading menu...';

    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        initialMenu = await _loadCachedMenu(cachedJson);
      } catch (error, stackTrace) {
        debugPrint('Menu cache parse failed: $error');
        debugPrint('$stackTrace');
        initialMenu = [];
      }
    }

    if (initialMenu.isEmpty) {
      try {
        initialMenu = await _loadAssetMenu();
      } catch (error, stackTrace) {
        debugPrint('JSON ERROR: $error');
        debugPrint('Menu asset load failed: $error');
        debugPrint('$stackTrace');
        initialMenu = [];
      }
    }

    state = AsyncData(initialMenu);

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (initialMenu.isNotEmpty) {
        loadMessage = 'Offline mode: Loaded local data';
      } else {
        state = AsyncError(
          'No menu data available offline',
          StackTrace.current,
        );
        loadMessage = 'Offline mode: Failed to load menu';
      }
      return loadMessage;
    }

    try {
      final remote = await ApiService().getMenu();
      if (remote.isNotEmpty) {
        await prefs.setString(
          cacheKey,
          jsonEncode(remote.map((item) => item.toJson()).toList()),
        );
        state = AsyncData(remote);
        loadMessage = 'Loaded from API';
      } else if (initialMenu.isNotEmpty) {
        loadMessage = 'Loaded local data';
      } else {
        state = AsyncError('Menu API returned no items', StackTrace.current);
        loadMessage = 'Failed to load menu from API';
      }
    } catch (error, stackTrace) {
      debugPrint('Menu remote fetch failed: $error');
      debugPrint('$stackTrace');
      if (initialMenu.isNotEmpty) {
        state = AsyncData(initialMenu);
        loadMessage = 'Loaded local data';
      } else {
        state = AsyncError('Failed to load menu', StackTrace.current);
        loadMessage = 'Failed to load menu';
      }
    }

    return loadMessage;
  }

  Future<void> refreshMenu() async {
    await loadMenu();
  }
}
