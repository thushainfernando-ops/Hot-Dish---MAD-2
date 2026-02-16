import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Menu Detail Screen - Master/Detail Pattern
/// Shows detailed information about a selected menu item
class MenuDetailScreen extends StatefulWidget {
  final Product product;

  const MenuDetailScreen({super.key, required this.product});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${widget.product.id}',
                child: _buildImage(isDark),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: theme.textTheme.displaySmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Rs. ${widget.product.price.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rating
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              color:
                                  index < 4
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '4.5 (120 reviews)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text('Description', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),

                      // Ingredients (Sample)
                      Text(
                        'Key Ingredients',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildIngredientChip('Rice', isDark),
                          _buildIngredientChip('Curry', isDark),
                          _buildIngredientChip('Coconut', isDark),
                          _buildIngredientChip('Spices', isDark),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Quantity Selector
                      Text('Quantity', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 32,
                            color: AppColors.primaryOrange,
                          ),
                          Container(
                            width: 60,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 32,
                            color: AppColors.primaryOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final provider = Provider.of<AppProvider>(
                              context,
                              listen: false,
                            );
                            final success = await provider.addToCart(
                              widget.product,
                              _quantity,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Added to cart!'
                                        : 'Failed to add to cart',
                                  ),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              if (success) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: Text('Add $_quantity to Cart'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Builder(
          builder: (context) {
            if (widget.product.image.startsWith('http')) {
              return Image.network(
                widget.product.image,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 80),
                    ),
              );
            } else {
              return Image.asset(
                widget.product.image,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood, size: 80),
                    ),
              );
            }
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withAlpha((0.7 * 255).round()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientChip(String label, bool isDark) {
    return Chip(
      label: Text(label),
      backgroundColor: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
      labelStyle: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
    );
  }
}
