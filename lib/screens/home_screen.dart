import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'about_screen.dart';

/// Modern Home Screen matching the Hot Dish website
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Section with Background Image
          SliverToBoxAdapter(child: _buildHeroSection(context, isDark)),

          // Features Section
          SliverToBoxAdapter(child: _buildFeaturesSection(theme)),

          // Specialties Section
          SliverToBoxAdapter(child: _buildSpecialtiesSection(context, theme)),

          // Testimonials Section
          SliverToBoxAdapter(child: _buildTestimonialsSection(theme, isDark)),

          // CTA Section
          SliverToBoxAdapter(child: _buildCTASection(context, theme)),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final heroHeight = isLandscape ? 300.0 : min(screenHeight * 0.7, 550.0);

    return Container(
      height: heroHeight,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/home-bg-new.jpg'),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.darkBlue.withAlpha((0.9 * 255).round()),
            AppColors.darkBlue2.withAlpha((0.8 * 255).round()),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBlue.withAlpha((0.9 * 255).round()),
              AppColors.darkBlue2.withAlpha((0.7 * 255).round()),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: isLandscape ? 60 : 80,
                  height: isLandscape ? 60 : 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.restaurant,
                            size: 40,
                            color: AppColors.primaryOrange,
                          ),
                    ),
                  ),
                ),
                SizedBox(height: isLandscape ? 20 : 40),

                // Title
                Text(
                  'Authentic Sri Lankan',
                  style: TextStyle(
                    fontSize: isLandscape ? 24 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Flavors',
                      style: TextStyle(
                        fontSize: isLandscape ? 24 : 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    SizedBox(width: isLandscape ? 4 : 8),
                    Text(
                      'Delivered',
                      style: TextStyle(
                        fontSize: isLandscape ? 24 : 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLandscape ? 8 : 16),

                // Subtitle
                Text(
                  'Experience the rich taste of traditional Sri Lankan cuisine. Fresh ingredients, authentic recipes, delivered to your door.',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: isLandscape ? 16 : 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final provider = Provider.of<AppProvider>(
                            context,
                            listen: false,
                          );
                          provider.setSelectedIndex(1);
                        },
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Order Now'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Learn More',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.delivery_dining,
                  title: 'Fast Delivery',
                  description:
                      'Get your food delivered hot and fresh within 30 minutes',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.restaurant,
                  title: 'Authentic Recipes',
                  description:
                      'Traditional Sri Lankan dishes made with love and care',
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.eco,
            title: 'Fresh Ingredients',
            description: 'Only the finest locally sourced ingredients',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryOrange, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtiesSection(BuildContext context, ThemeData theme) {
    final specialties = [
      {
        'name': 'Rice & Curry',
        'description': 'Authentic Sri Lankan rice with 5 delicious curries',
        'price': 'Rs. 850',
        'image': 'assets/rice-and-curry.jpg',
        'badge': 'Popular',
      },
      {
        'name': 'Seafood Noodles',
        'description': 'Fresh seafood stir-fried with noodles',
        'price': 'Rs. 1,250',
        'image': 'assets/seafood-noodles-new.jpg',
      },
      {
        'name': 'Mixed Fried Rice',
        'description': 'Special fried rice with mixed meats',
        'price': 'Rs. 1,400',
        'image': 'assets/mixed-fried-rice.jpg',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Our Specialties', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Discover our most loved dishes',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...specialties.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildSpecialtyCard(item, theme),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Full Menu'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard(Map<String, dynamic> item, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(item['image']),
                fit: BoxFit.cover,
              ),
            ),
            child:
                item['badge'] != null
                    ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['badge'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    : null,
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['price'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(ThemeData theme, bool isDark) {
    final testimonials = [
      {
        'name': 'Samantha Fernando',
        'role': 'Regular Customer',
        'review':
            'Best Sri Lankan food I\'ve ever tasted! The rice and curry is absolutely amazing. Highly recommend!',
        'initials': 'SF',
      },
      {
        'name': 'Rajesh Kumar',
        'role': 'Food Enthusiast',
        'review':
            'Excellent service and authentic flavors. The delivery is always on time and the food is hot!',
        'initials': 'RK',
      },
    ];

    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF9FAFB),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What Our Customers Say', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Real reviews from real customers',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...testimonials.map(
            (testimonial) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTestimonialCard(testimonial, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(
    Map<String, String> testimonial,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (index) =>
                    const Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"${testimonial['review']}"',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryOrange.withAlpha(
                    (0.1 * 255).round(),
                  ),
                  child: Text(
                    testimonial['initials']!,
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial['name']!,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      testimonial['role']!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Order?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Experience authentic Sri Lankan cuisine today',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(
                Icons.restaurant_menu,
                color: AppColors.primaryOrange,
              ),
              label: const Text(
                'Browse Menu',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
