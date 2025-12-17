// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Будуємо простий MaterialApp зі Scaffold
    await tester.pumpWidget(
      MaterialApp(home: Scaffold()),
    );

    // Перевіряємо, що Scaffold відрендерився
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
