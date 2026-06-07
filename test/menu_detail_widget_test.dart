import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_dish_mobile_app/models/app_models.dart';
import 'package:hot_dish_mobile_app/screens/menu_detail_screen.dart';

void main() {
  testWidgets('MenuDetailScreen displays product info', (
    WidgetTester tester,
  ) async {
    final product = Product(
      id: 'test-1',
      name: 'Test Dish',
      description: 'A tasty test dish',
      price: 123.0,
      image: 'assets/images/kottu.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(home: MenuDetailScreen(product: product)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Dish'), findsOneWidget);
    expect(find.text('Rs. 123'), findsOneWidget);
    expect(find.text('A tasty test dish'), findsOneWidget);
  });
}
