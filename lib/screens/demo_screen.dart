import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/demo_service.dart';
import '../utils/constants.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  bool _isLoading = false;
  String _status = 'Ready to simulate backend responses.';
  User? _demoUser;
  List<Product> _menuItems = [];
  List<CartItem> _cartItems = [];
  bool _checkoutSuccess = false;

  Future<void> _runDemo() async {
    setState(() {
      _isLoading = true;
      _status = 'Simulating login and loading menu...';
      _checkoutSuccess = false;
    });

    final user = await DemoService.simulateLogin();
    final menu = await DemoService.simulateMenu();
    final cart = await DemoService.simulateCart(menu);

    setState(() {
      _demoUser = user;
      _menuItems = menu;
      _cartItems = cart;
      _status =
          'Demo backend loaded successfully. Add items to cart and checkout.';
      _isLoading = false;
    });
  }

  void _addToCart(Product product) {
    final index = _cartItems.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      setState(() => _cartItems[index].quantity += 1);
      return;
    }
    setState(() {
      _cartItems.add(
        CartItem(
          id: 'demo_cart_${product.id}',
          productId: product.id,
          name: product.name,
          price: product.price,
          image: product.image,
          quantity: 1,
        ),
      );
    });
  }

  Future<void> _checkout() async {
    setState(() {
      _isLoading = true;
      _status = 'Processing simulated checkout...';
    });
    final success = await DemoService.simulateCheckout();
    setState(() {
      _checkoutSuccess = success;
      _status =
          success
              ? 'Checkout successful! Order confirmed.'
              : 'Checkout failed.';
      _isLoading = false;
    });
  }

  double get _demoTotal =>
      _cartItems.fold(0, (total, item) => total + item.price * item.quantity);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Backend Flow')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulated backend mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This demo uses local asset data to simulate API responses and checkout flow.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'API base URL: ${AppConstants.baseUrl}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $_status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _runDemo,
              child: Text(_demoUser == null ? 'Start Demo' : 'Reload Demo'),
            ),
            const SizedBox(height: 12),
            if (_demoUser != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_demoUser!.name),
                  subtitle: Text('${_demoUser!.email}\n${_demoUser!.address}'),
                  isThreeLine: true,
                ),
              ),
            const SizedBox(height: 12),
            if (_menuItems.isNotEmpty) ...[
              const Text(
                'Menu Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return Card(
                      child: ListTile(
                        leading:
                            item.image.isNotEmpty
                                ? Image.asset(
                                  item.image,
                                  width: 50,
                                  fit: BoxFit.cover,
                                )
                                : const Icon(Icons.fastfood),
                        title: Text(item.name),
                        subtitle: Text('Rs. ${item.price.toStringAsFixed(0)}'),
                        trailing: ElevatedButton(
                          onPressed: () => _addToCart(item),
                          child: const Text('Add'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_cartItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Cart Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'Qty ${item.quantity} • Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: Rs. ${_demoTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkout,
                child: const Text('Checkout (Simulated)'),
              ),
              if (_checkoutSuccess) ...[
                const SizedBox(height: 8),
                Text(
                  'Demo checkout completed successfully.',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
