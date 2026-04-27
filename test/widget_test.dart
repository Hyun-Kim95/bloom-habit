import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('ProviderScope + MaterialApp smoke', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Bloom Habit test')),
          ),
        ),
      ),
    );
    expect(find.text('Bloom Habit test'), findsOneWidget);
  });
}
