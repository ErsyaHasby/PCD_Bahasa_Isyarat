import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyarat_translator/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IsyaratApp()));
    // Splash screen harus ada
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
