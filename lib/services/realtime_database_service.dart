import 'package:firebase_database/firebase_database.dart';
import '../models/app_models.dart';
import '../models/order.dart';

class RealtimeDatabaseService {
  RealtimeDatabaseService._();

  static final _db = FirebaseDatabase.instance;

  static DatabaseReference _usersRef() => _db.ref('users');
  static DatabaseReference _favoritesRef() => _db.ref('favorites');

  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String address,
    String? photoPath,
  }) async {
    final values = {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'photoPath': photoPath ?? '',
      'updatedAt': ServerValue.timestamp,
    };
    await _usersRef().child(uid).set(values);
  }

  static Future<User?> getUserProfile(String uid) async {
    final snapshot = await _usersRef().child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return User(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      photoPath: data['photoPath']?.toString() ?? '',
    );
  }

  static Future<String?> getUserPhotoPath(String uid) async {
    final snapshot = await _usersRef().child(uid).child('photoPath').get();
    return snapshot.exists ? snapshot.value?.toString() : null;
  }

  static Future<void> saveUserPhotoPath(String uid, String path) async {
    await _usersRef().child(uid).child('photoPath').set(path);
  }

  static Future<List<String>> getFavorites(String uid) async {
    final snapshot = await _favoritesRef().child(uid).child('items').get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final items = List<dynamic>.from(snapshot.value as List<dynamic>);
    return items.map((e) => e.toString()).toList();
  }

  static Future<void> saveFavorites(String uid, List<String> items) async {
    await _favoritesRef().child(uid).set({'items': items});
  }

  // Cart helpers
  static DatabaseReference _cartRef() => _db.ref('carts');
  static DatabaseReference _ordersRef() => _db.ref('orders');

  static Future<List<CartItem>> getCart(String uid) async {
    final snapshot = await _cartRef().child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final Map data = snapshot.value as Map;
    final items = <CartItem>[];
    data.forEach((key, value) {
      try {
        final map = Map<String, dynamic>.from(value as Map);
        items.add(
          CartItem(
            id: key.toString(),
            productId: map['productId']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
            price:
                (map['price'] is num)
                    ? (map['price'] as num).toDouble()
                    : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
            image: map['image']?.toString() ?? '',
            quantity:
                (map['quantity'] is int)
                    ? map['quantity'] as int
                    : int.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
          ),
        );
      } catch (_) {}
    });
    return items;
  }

  static Future<void> saveCart(String uid, List<CartItem> items) async {
    final Map<String, Map<String, dynamic>> payload = {};
    for (final it in items) {
      payload[it.id] = {
        'productId': it.productId,
        'name': it.name,
        'price': it.price,
        'image': it.image,
        'quantity': it.quantity,
      };
    }
    await _cartRef().child(uid).set(payload);
  }

  static Future<void> clearCart(String uid) async {
    await _cartRef().child(uid).remove();
  }

  static Future<void> setCartItem(String uid, CartItem item) async {
    final payload = {
      'productId': item.productId,
      'name': item.name,
      'price': item.price,
      'image': item.image,
      'quantity': item.quantity,
    };
    await _cartRef().child(uid).child(item.id).set(payload);
  }

  static Future<void> removeCartItem(String uid, String itemId) async {
    await _cartRef().child(uid).child(itemId).remove();
  }

  static Stream<List<CartItem>> cartStream(String uid) {
    return _cartRef().child(uid).onValue.map((event) {
      if (event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final items = <CartItem>[];
      data.forEach((key, value) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          items.add(
            CartItem(
              id: key.toString(),
              productId: map['productId']?.toString() ?? '',
              name: map['name']?.toString() ?? '',
              price:
                  (map['price'] is num)
                      ? (map['price'] as num).toDouble()
                      : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
              image: map['image']?.toString() ?? '',
              quantity:
                  (map['quantity'] is int)
                      ? map['quantity'] as int
                      : int.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
            ),
          );
        } catch (_) {}
      });
      return items;
    });
  }

  // Orders helpers
  static Future<void> saveOrder(
    String uid,
    Map<String, dynamic> orderData,
  ) async {
    final ref = _ordersRef().child(uid).push();
    final payload = {...orderData, 'created_at': ServerValue.timestamp};
    await ref.set(payload);
  }

  static Future<void> updateOrderStatus(
    String uid,
    String orderId,
    String status,
  ) async {
    await _ordersRef().child(uid).child(orderId).update({
      'status': status,
      'updated_at': ServerValue.timestamp,
    });
  }

  static Future<void> setOrder(
    String uid,
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    final payload = {...orderData, 'updated_at': ServerValue.timestamp};
    await _ordersRef().child(uid).child(orderId).set(payload);
  }

  static Future<List<Order>> getOrders(String uid) async {
    final snapshot = await _ordersRef().child(uid).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final Map data = snapshot.value as Map;
    final orders = <Order>[];
    data.forEach((key, value) {
      try {
        final map = Map<String, dynamic>.from(value as Map);
        orders.add(Order.fromJson({'id': key, ...map}));
      } catch (_) {}
    });
    // sort by created_at if available
    orders.sort((a, b) => b.date.compareTo(a.date));
    return orders;
  }

  static Stream<List<Order>> ordersStream(String uid) {
    return _ordersRef().child(uid).onValue.map((event) {
      if (event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final orders = <Order>[];
      data.forEach((key, value) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          orders.add(Order.fromJson({'id': key, ...map}));
        } catch (_) {}
      });
      orders.sort((a, b) => b.date.compareTo(a.date));
      return orders;
    });
  }
}
