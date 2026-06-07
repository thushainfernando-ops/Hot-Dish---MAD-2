import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../services/geolocation_service.dart';

/// Payment Screen with Card Payment and Cash on Delivery
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _addressController = TextEditingController();

  String _paymentMethod = 'card'; // 'card' or 'cod'
  bool _isProcessing = false;
  bool _isGettingLocation = false;

  // Location data
  double? _userLatitude;
  double? _userLongitude;
  double? _distanceKm;
  int? _estimatedDeliveryMinutes;
  String _locationStatus = 'Not fetched';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Fetch current location and calculate delivery info
  Future<void> _useMyLocation() async {
    setState(() => _isGettingLocation = true);

    final deliveryInfo = await GeolocationService.getDeliveryInfo();

    if (!mounted) return;

    if (deliveryInfo != null) {
      setState(() {
        _userLatitude = deliveryInfo['latitude'];
        _userLongitude = deliveryInfo['longitude'];
        _distanceKm = deliveryInfo['distance_km'];
        _estimatedDeliveryMinutes = deliveryInfo['estimated_minutes'];
        _locationStatus =
            'Location: ${deliveryInfo['distance_formatted']} from restaurant';
        // Prefer human-readable address if reverse geocoding succeeded
        final addr = deliveryInfo['address'] as String?;
        if (addr != null && addr.isNotEmpty) {
          _addressController.text = addr;
        } else {
          _addressController.text =
              '${_userLatitude?.toStringAsFixed(4)}, ${_userLongitude?.toStringAsFixed(4)}';
        }
        _isGettingLocation = false;
      });

      // Show snackbar with delivery info
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Distance: ${deliveryInfo['distance_formatted']} | Estimated: ${deliveryInfo['estimated_minutes']} min',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _locationStatus = 'Failed to get location';
        _isGettingLocation = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to get location. Please enable location services and grant permission.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    final provider = Provider.of<AppProvider>(context, listen: false);

    final paymentDetails = {
      'payment_method': _paymentMethod,
      'delivery_address': _addressController.text.trim(),
      if (_userLatitude != null && _userLongitude != null) ...{
        'latitude': _userLatitude.toString(),
        'longitude': _userLongitude.toString(),
        'distance_km': _distanceKm.toString(),
        'estimated_delivery_minutes': _estimatedDeliveryMinutes.toString(),
      },
      if (_paymentMethod == 'card') ...{
        'card_number': _cardNumberController.text,
        'expiry': _expiryController.text,
        'cvv': _cvvController.text,
        'card_holder': _cardHolderController.text,
      },
    };

    final success = await provider.placeOrder(paymentDetails);

    if (mounted) {
      setState(() => _isProcessing = false);

      if (success) {
        Navigator.pushReplacementNamed(context, '/order-success');
      } else {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment failed. Please try again.'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), elevation: 0),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Text('Order Summary', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', provider.subtotal, theme),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Delivery Fee', 250, theme),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Total',
                          provider.total,
                          theme,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Delivery Address Section with GPS
                Text('Delivery Address', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),

                // GPS Location Card
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GPS Location',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _locationStatus,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  _isGettingLocation ? null : _useMyLocation,
                              icon:
                                  _isGettingLocation
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                        ),
                                      )
                                      : const Icon(Icons.location_on, size: 18),
                              label: const Text('Use My Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_distanceKm != null &&
                            _estimatedDeliveryMinutes != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Distance',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      GeolocationService.formatDistance(
                                        _distanceKm!,
                                      ),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: AppColors.primaryOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Est. Delivery',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      ' min',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Form for address and card details
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Address TextField
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          hintText: 'Enter or use GPS to auto-fill',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter delivery address or use GPS';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Payment Method Selection
                      Text(
                        'Payment Method',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      // Card Payment Option
                      Card(
                        child: RadioListTile<String>(
                          value: 'card',
                          groupValue: _paymentMethod,
                          onChanged:
                              (value) =>
                                  setState(() => _paymentMethod = value!),
                          title: const Text('Credit/Debit Card'),
                          subtitle: const Text('Pay securely with your card'),
                          secondary: const Icon(
                            Icons.credit_card,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cash on Delivery Option
                      Card(
                        child: RadioListTile<String>(
                          value: 'cod',
                          groupValue: _paymentMethod,
                          onChanged:
                              (value) =>
                                  setState(() => _paymentMethod = value!),
                          title: const Text('Cash on Delivery'),
                          subtitle: const Text(
                            'Pay when you receive your order',
                          ),
                          secondary: const Icon(
                            Icons.money,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Card Payment Form (shown only if card is selected)
                      if (_paymentMethod == 'card') ...[
                        Text(
                          'Card Details',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),

                        // Card Number
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: '1234 5678 9012 3456',
                            prefixIcon: const Icon(Icons.credit_card),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CardNumberInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card number';
                            }
                            final digits = value.replaceAll(' ', '');
                            if (digits.length < 13 || digits.length > 19) {
                              return 'Invalid card number';
                            }
                            if (!_luhnCheck(digits)) {
                              return 'Invalid card number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Expiry and CVV
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                decoration: InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'MM/YY',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(
                                    r'^\d{2}/\d{2}$',
                                  ).hasMatch(value)) {
                                    return 'Invalid format';
                                  }
                                  final parts = value.split('/');
                                  final month = int.parse(parts[0]);
                                  final year = int.parse(parts[1]);
                                  if (month < 1 || month > 12) {
                                    return 'Invalid month';
                                  }
                                  final fourYear = 2000 + year;
                                  final lastDay = DateTime(
                                    fourYear,
                                    month + 1,
                                    0,
                                  );
                                  final now = DateTime.now();
                                  if (lastDay.isBefore(
                                    DateTime(now.year, now.month, 1),
                                  )) {
                                    return 'Card expired';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                decoration: InputDecoration(
                                  labelText: 'CVV',
                                  hintText: '123',
                                  prefixIcon: const Icon(Icons.lock),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 3) {
                                    return 'Invalid CVV';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card Holder Name
                        TextFormField(
                          controller: _cardHolderController,
                          decoration: InputDecoration(
                            labelText: 'Card Holder Name',
                            hintText: 'JOHN DOE',
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card holder name';
                            }
                            if (value.length < 3) {
                              return 'Name too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    child:
                        _isProcessing
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _paymentMethod == 'card'
                                  ? 'Pay Rs. ${provider.total.toStringAsFixed(2)}'
                                  : 'Place Order',
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Security Note
                if (_paymentMethod == 'card')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your payment information is secure',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTotal
                  ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                  : theme.textTheme.bodyLarge,
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style:
              isTotal
                  ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  )
                  : theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool isEven = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll('/', '');
    if (text.length <= 2) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return TextEditingValue(
      text: '${text.substring(0, 2)}/${text.substring(2, min(4, text.length))}',
      selection: TextSelection.collapsed(
        offset: min(
          5,
          '${text.substring(0, 2)}/${text.substring(2, min(4, text.length))}'
              .length,
        ),
      ),
    );
  }
}

