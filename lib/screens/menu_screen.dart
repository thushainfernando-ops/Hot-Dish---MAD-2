import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../providers/menu_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connectivity_provider.dart';
import '../models/app_models.dart';
import '../utils/constants.dart';
import 'menu_detail_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final Map<String, String> _categoryDisplayNames = {
    'all': 'All',
    'beverages': 'Beverages',
    'devilled': 'Devilled',
    'rice-curry': 'Rice & Curry',
    'noodles': 'Noodles',
    'fried-rice': 'Fried Rice',
    'pasta': 'Pasta',
    'veggie': 'Vegetarian',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    Future.microtask(() async {
      final message = await ref.read(menuProvider.notifier).loadMenu();
      if (!mounted) return;
      _showMenuSnackbar(message);
    });
  }

  void _showMenuSnackbar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  List<Product> _getFilteredItems(
    List<Product> items,
    String selectedCategory,
  ) {
    if (selectedCategory == 'all') return items;
    return items.where((item) => item.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final message = await ref.read(menuProvider.notifier).loadMenu();
              if (!mounted) return;
              _showMenuSnackbar(message);
            },
            tooltip: 'Refresh menu',
          ),
        ],
      ),
      body: Column(
        children: [
          ref
              .watch(connectivityProvider)
              .when(
                data: (status) {
                  if (status == ConnectivityResult.none) {
                    return Container(
                      width: double.infinity,
                      color: theme.colorScheme.secondaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Offline: using cached/local menu data',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
          Expanded(
            child: ref
                .watch(menuProvider)
                .when(
                  data: (menuItems) {
                    if (menuItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No menu items available.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final message =
                                    await ref
                                        .read(menuProvider.notifier)
                                        .loadMenu();
                                if (!mounted) return;
                                _showMenuSnackbar(message);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final Set<String> categorySet = {'all'};
                    for (final p in menuItems) {
                      if (p.category != null && p.category!.trim().isNotEmpty) {
                        categorySet.add(p.category!.trim());
                      }
                    }
                    final categories = categorySet.toList();

                    String displayName(String key) {
                      if (_categoryDisplayNames.containsKey(key)) {
                        return _categoryDisplayNames[key]!;
                      }
                      return key
                          .replaceAll('-', ' ')
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map(
                            (w) =>
                                w.isEmpty
                                    ? w
                                    : '${w[0].toUpperCase()}${w.substring(1)}',
                          )
                          .join(' ');
                    }

                    return Column(
                      children: [
                        // Category chips (horizontal)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: List.generate(categories.length, (i) {
                              final catKey = categories[i];
                              final isSelected = _selectedIndex == i;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    displayName(catKey),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => _selectedIndex = i);
                                    _pageController.animateToPage(
                                      i,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  selectedColor: AppColors.primaryOrange,
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? AppColors.primaryOrange
                                            : theme.colorScheme.outline,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // PageView: horizontal swipe between categories; each page has a vertical GridView
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: categories.length,
                            onPageChanged:
                                (index) =>
                                    setState(() => _selectedIndex = index),
                            itemBuilder: (context, pageIndex) {
                              final catKey = categories[pageIndex];
                              final items = _getFilteredItems(
                                menuItems,
                                catKey,
                              );
                              if (items.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('No items in this category.'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final message =
                                              await ref
                                                  .read(menuProvider.notifier)
                                                  .loadMenu();
                                          if (!mounted) return;
                                          _showMenuSnackbar(message);
                                        },
                                        child: const Text('Refresh Menu'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isLandscape ? 4 : 2,
                                      childAspectRatio:
                                          isLandscape ? 0.65 : 0.7,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: items.length,
                                itemBuilder:
                                    (context, index) =>
                                        _buildMenuCard(context, items[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Failed to load menu',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final message =
                                    await ref
                                        .read(menuProvider.notifier)
                                        .loadMenu();
                                if (!mounted) return;
                                _showMenuSnackbar(message);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, Product product) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha((0.08 * 255).round()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Builder(
                  builder: (context) {
                    final heroTag = 'product-${product.id}';
                    if (product.image.startsWith('http')) {
                      return Hero(
                        tag: heroTag,
                        child: Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                        ),
                      );
                    } else {
                      return Hero(
                        tag: heroTag,
                        child: Image.asset(
                          product.image.isNotEmpty
                              ? product.image
                              : 'assets/placeholder.jpg',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.fastfood,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              height: 28,
                              width: 28,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final provider = p.Provider.of<AppProvider>(
                                    context,
                                    listen: false,
                                  );
                                  final success = await provider.addToCart(
                                    product,
                                    1,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Added to cart'
                                              : 'Failed to add',
                                        ),
                                        backgroundColor:
                                            success
                                                ? theme.colorScheme.secondary
                                                : theme.colorScheme.error,
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: AppColors.primaryOrange,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
