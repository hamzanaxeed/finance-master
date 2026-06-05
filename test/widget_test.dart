import 'package:cursor_bhai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads finance shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinancePsxApp()));
    await tester.pumpAndSettle();
    expect(find.text('Finance PSX'), findsOneWidget);
  });
}
