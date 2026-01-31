// Basic Flutter widget test for AgriSense Pro

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrisense_pro/main.dart';
import 'package:agrisense_pro/providers/app_provider.dart';

void main() {
  testWidgets('AgriSense Pro app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const AgriSenseApp(),
      ),
    );

    // Verify that app loads without errors
    await tester.pump(const Duration(seconds: 1));
    
    // App should start with splash screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
