import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Modern Profile Screen with User Details
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch user profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = provider.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No user data', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.fetchProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Gradient
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.darkBlue, AppColors.darkBlue2],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryOrange,
                              child: Text(
                                _getInitials(user.name),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Profile Information
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      // Info Cards
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        title: 'Full Name',
                        value: user.name,
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: user.email,
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        value:
                            user.phone.isNotEmpty ? user.phone : 'Not provided',
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.location_on_outlined,
                        title: 'Address',
                        value:
                            user.address.isNotEmpty
                                ? user.address
                                : 'Not provided',
                        theme: theme,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Hot Dish Info
                      Text(
                        'About Hot Dish',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      _buildActionButton(
                        icon: Icons.share_outlined,
                        title: 'Refer & Earn',
                        subtitle: 'Share Hot Dish with friends and get rewards',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Referral rewards program coming soon!',
                              ),
                            ),
                          );
                        },
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildActionButton(
                        icon: Icons.restaurant_outlined,
                        title: 'About Hot Dish',
                        subtitle: 'Learn about our restaurant',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Authentic Sri Lankan cuisine delivered fresh to your door',
                              ),
                            ),
                          );
                        },
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildActionButton(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Contact us for assistance',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Support team: support@hotdish.com',
                              ),
                            ),
                          );
                        },
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildActionButton(
                        icon: Icons.description_outlined,
                        title: 'Terms & Privacy',
                        subtitle: 'View our terms and conditions',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Terms & Privacy Policy available at hotdish.com',
                              ),
                            ),
                          );
                        },
                        theme: theme,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true && context.mounted) {
                              await provider.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
