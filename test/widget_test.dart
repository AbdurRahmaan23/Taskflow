import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/presentation/providers/providers.dart';
import 'package:taskflow/presentation/screens/login_screen.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('Login screen validates empty fields', (WidgetTester tester) async {
    // Inject mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

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
