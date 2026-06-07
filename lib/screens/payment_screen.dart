import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

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

  String _paymentMethod = 'card'; // 'card' or 'cod'
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_paymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    final provider = Provider.of<AppProvider>(context, listen: false);

    final paymentDetails = {
      'payment_method': _paymentMethod,
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

                // Payment Method Selection
                Text('Payment Method', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),

                // Card Payment Option
                Card(
                  child: RadioListTile<String>(
                    value: 'card',
                    groupValue: _paymentMethod,
                    onChanged:
                        (value) => setState(() => _paymentMethod = value!),
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
                        (value) => setState(() => _paymentMethod = value!),
                    title: const Text('Cash on Delivery'),
                    subtitle: const Text('Pay when you receive your order'),
                    secondary: const Icon(
                      Icons.money,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Card Payment Form (shown only if card is selected)
                if (_paymentMethod == 'card') ...[
                  Text('Card Details', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                                  // Convert YY to 2000+YY (assume cards won't be > 2100)
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

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
}

bool _luhnCheck(String digits) {
  int sum = 0;
  bool alternate = false;
  for (int i = digits.length - 1; i >= 0; i--) {
    int n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

// Card Number Formatter (adds spaces every 4 digits)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry Date Formatter (adds / after MM)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year =
          text.length > 2 ? text.substring(2, min(4, text.length)) : '';

      final formatted = year.isEmpty ? '$month/' : '$month/$year';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
