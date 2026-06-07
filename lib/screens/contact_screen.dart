import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

/// Contact Screen with Mobile Form
/// Demonstrates proper form implementation with validation
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedSubject = 'General Inquiry';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  double? _lat;
  double? _lon;
  bool _geocoding = false;

  @override
  void initState() {
    super.initState();
    _geocodeAddress();
  }

  Future<void> _geocodeAddress() async {
    setState(() => _geocoding = true);
    final address = 'No 225 Walagedara Balapitiya Sri Lanka';
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}',
    );
    try {
      final res = await http
          .get(url, headers: {'User-Agent': 'HotDishApp/1.0 (example)'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as List<dynamic>?;
        if (decoded != null && decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            _lat = lat;
            _lon = lon;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocoding = false);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final api = ApiService();
    final connectivity = await Connectivity().checkConnectivity();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (connectivity == ConnectivityResult.none) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'No internet connection. Please try again later.',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final success = await api.sendContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        subject: _selectedSubject,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Message sent successfully!'
                  : 'Unable to send message. Please try again.',
            ),
            backgroundColor:
                success
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success) {
          _formKey.currentState!.reset();
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _messageController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Get in Touch', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              'We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Contact Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field (Text Input)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field (Email Input)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'your.email@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field (Phone Input)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+94 XX XXX XXXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subject Dropdown (Dropdown Input)
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items:
                        [
                          'General Inquiry',
                          'Order Issue',
                          'Feedback',
                          'Reservation',
                          'Other',
                        ].map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubject = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Message Field (Multiline Text Input)
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Type your message here...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.message_outlined),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      if (value.length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child:
                          _isSubmitting
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Contact Information
            Text(
              'Other Ways to Reach Us',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            _buildContactInfo(
              icon: Icons.location_on_outlined,
              title: 'Address',
              subtitle:
                  'No 225, Walagedara, Balapitiya, Sri Lanka (near Balapitiya Base Hospital)',
              theme: theme,
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.hardEdge,
              elevation: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapUrl =
                      (_lat != null && _lon != null)
                          ? 'https://staticmap.openstreetmap.de/staticmap.php?center=${_lat!.toStringAsFixed(6)},${_lon!.toStringAsFixed(6)}&zoom=16&size=600x300&markers=${_lat!.toStringAsFixed(6)},${_lon!.toStringAsFixed(6)},red-pushpin'
                          : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surface,
                        child:
                            _geocoding
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : (mapUrl != null)
                                ? ClipRRect(
                                  borderRadius: BorderRadius.zero,
                                  child: Image.network(
                                    mapUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stack) => Center(
                                          child: Text(
                                            'Map preview unavailable',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                  ),
                                )
                                : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          size: 48,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Map preview unavailable',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final scaffold =
                                                ScaffoldMessenger.of(context);
                                            final query = Uri.encodeComponent(
                                              'No 225 Walagedara Balapitiya Sri Lanka',
                                            );
                                            final uri = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$query',
                                            );
                                            final opened = await launchUrl(
                                              uri,
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
                                            );
                                            if (!opened) {
                                              scaffold.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Could not open maps',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.map),
                                          label: const Text('Open in Maps'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No 225, Walagedara, Balapitiya, Sri Lanka',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final scaffold = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final query = Uri.encodeComponent(
                                      'No 225 Walagedara Balapitiya Sri Lanka',
                                    );
                                    final uri = Uri.parse(
                                      'https://www.google.com/maps/search/?api=1&query=$query',
                                    );
                                    final opened = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!opened) {
                                      scaffold.showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not open maps'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.map, size: 18),
                                  label: const Text('Open in Maps'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final scaffold = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final address =
                                        'No 225, Walagedara, Balapitiya, Sri Lanka';
                                    await Clipboard.setData(
                                      ClipboardData(text: address),
                                    );
                                    scaffold.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Address copied to clipboard',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_all, size: 18),
                                  label: const Text('Copy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            _buildContactInfo(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: '+94 11 234 5678',
              theme: theme,
            ),
            const SizedBox(height: 12),

            _buildContactInfo(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'info@hotdish.lk',
              theme: theme,
            ),
            const SizedBox(height: 12),

            _buildContactInfo(
              icon: Icons.access_time_outlined,
              title: 'Opening Hours',
              subtitle:
                  'Mon-Fri: 11:00 AM - 10:00 PM\nSat-Sun: 10:00 AM - 11:00 PM',
              theme: theme,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
