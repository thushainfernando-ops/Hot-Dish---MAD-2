import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/app_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/connectivity_provider.dart';
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
  AppProvider? _appProvider;
  bool _providerListenerAdded = false;

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
    // Load user profile and cart when scaffold initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      _appProvider = provider;
      provider.fetchProfile();
      provider.fetchCart();
      // prefetch menu so navigation feels faster
      try {
        riverpod.ProviderScope.containerOf(
          context,
          listen: false,
        ).read(menuProvider.notifier).loadMenu();
      } catch (_) {}
      // listen for programmatic navigation requests
      provider.addListener(_providerNavigationListener);
      _providerListenerAdded = true;
    });
  }

  @override
  void dispose() {
    if (_providerListenerAdded && _appProvider != null) {
      _appProvider!.removeListener(_providerNavigationListener);
    }
    _pageController.dispose();
    super.dispose();
  }

  void _providerNavigationListener() {
    if (!mounted) return;
    final provider = _appProvider;
    if (provider == null) return;
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          riverpod.Consumer(
            builder: (context, ref, child) {
              final connectivity = ref.watch(connectivityProvider);
              return connectivity.when(
                data: (status) {
                  if (status == ConnectivityResult.none) {
                    return Container(
                      width: double.infinity,
                      color: theme.colorScheme.errorContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Offline mode: showing cached data where available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: _screens,
            ),
          ),
        ],
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
