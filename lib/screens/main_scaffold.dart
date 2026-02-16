import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'contact_screen.dart';

/// Main Scaffold with Bottom Navigation and Cart Badge
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = const [
    HomeScreen(),
    MenuScreen(),
    CartScreen(),
    ContactScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Load cart when scaffold initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.fetchCart();
      // listen for programmatic navigation requests
      provider.addListener(_providerNavigationListener);
    });
  }

  @override
  void dispose() {
    // remove provider listener if exists
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.removeListener(_providerNavigationListener);
    } catch (_) {}
    _pageController.dispose();
    super.dispose();
  }

  void _providerNavigationListener() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final idx = provider.selectedIndex;
    if (idx != _currentIndex) {
      _onDestinationSelected(idx);
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    // keep provider in sync
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.setSelectedIndex(index);
    } catch (_) {}
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _screens,
      ),
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final cartCount = provider.cartItems.length;

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            animationDuration: const Duration(milliseconds: 400),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Menu',
              ),
              NavigationDestination(
                icon:
                    cartCount > 0
                        ? badges.Badge(
                          badgeContent: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined),
                        )
                        : const Icon(Icons.shopping_cart_outlined),
                selectedIcon:
                    cartCount > 0
                        ? badges.Badge(
                          badgeContent: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          child: const Icon(Icons.shopping_cart),
                        )
                        : const Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.contact_mail_outlined),
                selectedIcon: Icon(Icons.contact_mail),
                label: 'Contact',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
