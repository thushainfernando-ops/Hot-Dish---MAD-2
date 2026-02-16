import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/constants.dart';
import 'menu_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchMenu();
    });
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const Text('Our Menu')),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.menuItems.isEmpty) {
            return const Center(child: Text('No menu items available.'));
          }

          // Build categories dynamically from available menu items
          final Set<String> categorySet = {'all'};
          for (final p in provider.menuItems) {
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
                      w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
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
                                isSelected ? Colors.white : AppColors.darkBlue,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedIndex = i);
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: AppColors.primaryOrange,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? AppColors.primaryOrange
                                  : Colors.grey[300]!,
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
                      (index) => setState(() => _selectedIndex = index),
                  itemBuilder: (context, pageIndex) {
                    final catKey = categories[pageIndex];
                    final items = _getFilteredItems(provider.menuItems, catKey);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 4 : 2,
                        childAspectRatio: isLandscape ? 0.65 : 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder:
                          (context, index) =>
                              _buildMenuCard(context, items[index], provider),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    Product product,
    AppProvider provider,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
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
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
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
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
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
                        SizedBox(
                          height: 28,
                          width: 28,
                          child: ElevatedButton(
                            onPressed: () async {
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
                                        success ? Colors.green : Colors.red,
                                    duration: const Duration(milliseconds: 800),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.primaryOrange,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
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
