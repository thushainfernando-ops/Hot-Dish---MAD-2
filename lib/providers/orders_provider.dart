import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/realtime_database_service.dart';

class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;
  StreamSubscription<List<Order>>? _sub;

  List<Order> get orders => _orders;
  bool get loading => _loading;

  void _cancelSub() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> fetchOrders({bool force = false}) async {
    if (_orders.isNotEmpty && !force) return;
    _loading = true;
    notifyListeners();

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      _cancelSub();
      _sub = RealtimeDatabaseService.ordersStream(authUser.uid).listen(
        (list) {
          _orders = list;
          _loading = false;
          notifyListeners();
        },
        onError: (_) async {
          // fallback to API
          await _fetchFromApiOrSample();
        },
      );
      return;
    }

    await _fetchFromApiOrSample();
  }

  Future<void> _fetchFromApiOrSample() async {
    final api = ApiService();
    try {
      final userId = await api.getToken();
      if (userId != null) {
        final raw = await api.getOrders(userId);
        if (raw.isNotEmpty) {
          _orders =
              raw.map((e) {
                try {
                  return Order.fromJson(e as Map<String, dynamic>);
                } catch (_) {
                  return Order.sample('0');
                }
              }).toList();
        }
      }
    } catch (_) {}

    if (_orders.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      _orders = List.generate(8, (i) {
        final id = (i + 1).toString();
        final status = OrderStatus.values[i % OrderStatus.values.length];
        return Order.sample(id, status: status);
      });
    }

    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSub();
    super.dispose();
  }
}
