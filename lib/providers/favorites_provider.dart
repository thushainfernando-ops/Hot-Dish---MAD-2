import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/realtime_database_service.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Try Firestore for logged-in user
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      try {
        final items = await RealtimeDatabaseService.getFavorites(fbUser.uid);
        if (items.isNotEmpty) {
          state = items;
          await prefs.setString('favorites', jsonEncode(state));
          return;
        }
      } catch (_) {}
    }

    final raw = prefs.getString('favorites') ?? '[]';
    state = List<String>.from(jsonDecode(raw));
  }

  Future<void> toggle(String id, {String? userId}) async {
    final list = List<String>.from(state);
    if (list.contains(id)) {
      list.remove(id);
      state = list;
    } else {
      list.add(id);
      state = list;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', jsonEncode(state));

    // If user is provided, sync with Realtime Database
    if (userId != null) {
      await RealtimeDatabaseService.saveFavorites(userId, state);
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
      return FavoritesNotifier();
    });
