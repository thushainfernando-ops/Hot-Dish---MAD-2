import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
import '../services/realtime_database_service.dart';
import '../models/app_models.dart' show CartItem;
import '../providers/app_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final int? displayIndex;

  const OrderDetailScreen({super.key, required this.order, this.displayIndex});

  Widget _buildItem(BuildContext context, OrderItem it) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(it.name)),
          Text('x${it.quantity}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Text(
            'Rs ${(it.price * it.quantity).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayIndex != null
              ? 'Order ${(displayIndex! + 1).toString().padLeft(2, '0')}'
              : 'Order ${order.id}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${order.date.toLocal().toString().split(' ').first}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map((it) => _buildItem(context, it)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Rs ${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Status: ${order.status.toString().split('.').last}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      // cancel order
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Cancel Order'),
                              content: const Text(
                                'Are you sure you want to cancel this order?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await RealtimeDatabaseService.updateOrderStatus(
                          user.uid,
                          order.id,
                          'cancelled',
                        );
                        // try to sync to API (best-effort)
                        try {
                          // If server_order_id exists try update
                        } catch (_) {}
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order cancelled')),
                        );
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      // Reorder: push items into cart in RTDB and refresh provider
                      final cartItems =
                          order.items
                              .map(
                                (it) => CartItem(
                                  id: it.id,
                                  productId: it.id,
                                  name: it.name,
                                  price: it.price,
                                  image: '',
                                  quantity: it.quantity,
                                ),
                              )
                              .toList();

                      await RealtimeDatabaseService.saveCart(
                        user.uid,
                        cartItems,
                      );
                      if (!context.mounted) return;
                      try {
                        Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).fetchCart();
                      } catch (_) {}
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    icon: const Icon(Icons.repeat),
                    label: const Text('Reorder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
