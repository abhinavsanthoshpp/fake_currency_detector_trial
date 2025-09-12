import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:currency_scanner/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const VeriScanProApp());
    expect(find.text('VeriScan Pro'), findsOneWidget);
  });
}