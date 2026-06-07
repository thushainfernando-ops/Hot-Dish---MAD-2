// Order model for master/detail demo

enum OrderStatus { pending, preparing, onDelivery, delivered, cancelled }

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'price': price,
  };
}

class Order {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.status = OrderStatus.pending,
  });

  factory Order.sample(
    String id, {
    OrderStatus status = OrderStatus.delivered,
  }) {
    final items = [
      OrderItem(id: 'p1', name: 'Classic Burger', quantity: 1, price: 650.0),
      OrderItem(id: 'p2', name: 'French Fries', quantity: 2, price: 220.0),
    ];
    final total = items.fold<double>(0.0, (s, i) => s + i.price * i.quantity);
    final idNum = int.tryParse(id) ?? 0;
    final days = idNum % 5;
    return Order(
      id: id,
      date: DateTime.now().subtract(Duration(days: days)),
      items: items,
      total: total,
      status: status,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] ?? json['order_items'] ?? [];
    final items = <OrderItem>[];
    if (itemsJson is List) {
      for (final it in itemsJson) {
        try {
          items.add(
            OrderItem(
              id: it['id']?.toString() ?? it['product_id']?.toString() ?? '',
              name: it['name'] ?? it['title'] ?? '',
              quantity: int.tryParse(it['quantity']?.toString() ?? '1') ?? 1,
              price: double.tryParse(it['price']?.toString() ?? '0') ?? 0.0,
            ),
          );
        } catch (_) {}
      }
    }

    final total =
        double.tryParse(
          json['total']?.toString() ?? json['amount']?.toString() ?? '',
        ) ??
        items.fold<double>(0.0, (s, i) => s + i.price * i.quantity);

    final statusString =
        (json['status'] ?? json['order_status'] ?? '').toString().toLowerCase();
    OrderStatus status = OrderStatus.pending;
    if (statusString.contains('deliver')) {
      status = OrderStatus.delivered;
    }
    if (statusString.contains('cancel')) {
      status = OrderStatus.cancelled;
    }
    if (statusString.contains('prepare')) {
      status = OrderStatus.preparing;
    }
    if (statusString.contains('on') || statusString.contains('delivery')) {
      status = OrderStatus.onDelivery;
    }

    DateTime date = DateTime.now();
    try {
      if (json['date'] != null) {
        date = DateTime.parse(json['date'].toString());
      } else if (json['created_at'] != null) {
        date = DateTime.parse(json['created_at'].toString());
      }
    } catch (_) {
      // ignore parsing failures and keep current date
    }

    return Order(
      id: json['id']?.toString() ?? json['order_id']?.toString() ?? '',
      date: date,
      items: items,
      total: total,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'status': status.toString().split('.').last,
    };
  }
}
