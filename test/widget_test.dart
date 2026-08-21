import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/presentation/screens/login_screen.dart';

void main() {
  testWidgets('Login screen validates empty fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify that the login button is present
    expect(find.text('Login'), findsOneWidget);

    // Tap the login button without entering anything
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify validation errors are shown
    expect(find.text('Please enter email'), findsOneWidget);
    expect(find.text('Please enter password'), findsOneWidget);
  });
}
