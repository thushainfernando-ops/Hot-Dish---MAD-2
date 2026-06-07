import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../services/realtime_database_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'dart:io';
import 'order_history_screen.dart';

/// Modern Profile Screen with User Details
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = p.Provider.of<AppProvider>(context, listen: false);
      provider.fetchProfile();
      _loadStoredPhoto();
    });
  }

  Future<void> _loadStoredPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString('profile_photo');
    if (localPath != null) {
      final savedFile = File(localPath);
      if (await savedFile.exists()) {
        if (!mounted) return;
        setState(() {
          _photoFile = savedFile;
        });
        return;
      }
    }

    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) return;

    final dbPath = await RealtimeDatabaseService.getUserPhotoPath(authUser.uid);
    if (dbPath != null && dbPath.isNotEmpty) {
      final savedFile = File(dbPath);
      if (await savedFile.exists()) {
        if (!mounted) return;
        setState(() {
          _photoFile = savedFile;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final savedFile = File(
      '${appDir.path}${Platform.pathSeparator}profile_photo_${authUser.uid}.jpg',
    );
    final copiedFile = await File(picked.path).copy(savedFile.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo', copiedFile.path);

    await RealtimeDatabaseService.saveUserPhotoPath(
      authUser.uid,
      copiedFile.path,
    );

    if (!mounted) return;
    setState(() {
      _photoFile = copiedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authStateChangesProvider);
    final connectivity = ref.watch(connectivityProvider);
    final favorites = ref.watch(favoritesProvider);

    // Handle auth async state explicitly to avoid ambiguous `when` overloads
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authState.hasError) {
      return Scaffold(body: Center(child: Text('Auth error')));
    }

    // final user = authState.value; // not used directly here
    return Scaffold(
      body: p.Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userModel = provider.currentUser;
          if (userModel == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 80,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                          // Avatar with photo option
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primaryOrange,
                                backgroundImage:
                                    _photoFile != null
                                        ? FileImage(_photoFile!)
                                            as ImageProvider
                                        : null,
                                child:
                                    _photoFile == null
                                        ? Text(
                                          _getInitials(userModel.name),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userModel.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userModel.email,
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
                        value: userModel.name,
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: userModel.email,
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        value:
                            userModel.phone.isNotEmpty
                                ? userModel.phone
                                : 'Not provided',
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.location_on_outlined,
                        title: 'Address',
                        value:
                            userModel.address.isNotEmpty
                                ? userModel.address
                                : 'Not provided',
                        theme: theme,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Device & Connectivity',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      // Connectivity status
                      connectivity.when(
                        data: (status) {
                          final online = status != ConnectivityResult.none;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                online ? Icons.wifi : Icons.wifi_off,
                                color:
                                    online
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.error,
                              ),
                              title: const Text('Network'),
                              subtitle: Text(
                                online ? 'Connected' : 'No network',
                              ),
                              trailing: Text(
                                online ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color:
                                      online
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                        loading:
                            () => const Card(
                              child: ListTile(
                                leading: Icon(Icons.wifi),
                                title: Text('Network'),
                                subtitle: Text('Checking connectivity...'),
                              ),
                            ),
                        error:
                            (_, __) => const Card(
                              child: ListTile(
                                leading: Icon(Icons.wifi_off),
                                title: Text('Network'),
                                subtitle: Text(
                                  'Unable to determine connection',
                                ),
                              ),
                            ),
                      ),

                      const SizedBox(height: 12),

                      const SizedBox(height: 12),

                      // Favorites summary
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.favorite_outline),
                          title: const Text('Favourites'),
                          subtitle: Text('${favorites.length} items saved'),
                          trailing: IconButton(
                            icon: const Icon(Icons.manage_accounts),
                            onPressed: () async {
                              // sync favorites to Firestore if user logged in
                              final authUser =
                                  ref.read(authStateChangesProvider).value;
                              if (authUser != null) {
                                final messenger = ScaffoldMessenger.maybeOf(
                                  context,
                                );
                                await RealtimeDatabaseService.saveFavorites(
                                  authUser.uid,
                                  favorites,
                                );
                                if (!mounted) return;
                                messenger?.showSnackBar(
                                  const SnackBar(
                                    content: Text('Favourites synced'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

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
                        icon: Icons.receipt_long,
                        title: 'Orders History',
                        subtitle: 'View past orders and details',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen(),
                            ),
                          );
                        },
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Device Info and Backend Demo removed per request
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
                                          backgroundColor:
                                              theme.colorScheme.error,
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true && context.mounted) {
                              // Sign out Firebase and app provider
                              await FirebaseAuth.instance.signOut();
                              await provider.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.logout,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            'Logout',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.error,
                              width: 2,
                            ),
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
        }, // builder
      ), // p.Consumer
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
