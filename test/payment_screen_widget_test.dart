import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hot_dish_mobile_app/screens/payment_screen.dart';
import 'package:hot_dish_mobile_app/providers/app_provider.dart';

class TestAppProvider extends AppProvider {
  @override
  double get subtotal => 100.0;

  @override
  double get total => 350.0;

  @override
  Future<bool> placeOrder(Map<String, String> paymentDetails) async {
    return true;
  }
}

void main() {
  testWidgets('PaymentScreen shows Use My Location and address field', (
    WidgetTester tester,
  ) async {
    final provider = TestAppProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: PaymentScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Use My Location'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Delivery Address'),
      findsOneWidget,
    );
  });
}
