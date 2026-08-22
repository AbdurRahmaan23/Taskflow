import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/providers/providers.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockProjectRepository extends Mock implements ProjectRepository {}
class MockTaskRepository extends Mock implements TaskRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  testWidgets('Integration Test: Login and Dashboard flow', (WidgetTester tester) async {
    // Inject mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockAuthRepo = MockAuthRepository();
    final mockProjRepo = MockProjectRepository();
    final mockTaskRepo = MockTaskRepository();
    final mockNotifRepo = MockNotificationRepository();

    const mockUser = AuthCredentials(id: 'user_1', email: 'test@test.com', password: '', orgId: 'org1', role: 'member');
    when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);
    when(() => mockAuthRepo.login('test@test.com', 'password')).thenAnswer((_) async => const MockLoginResponse(accessToken: '', refreshToken: '', accessTokenExpiresIn: 0, refreshTokenExpiresIn: 0));
    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => mockUser);

    final mockProjects = [
      Project(id: 'p1', orgId: 'org1', name: 'Project 1', description: 'Desc 1', taskCount: 2, status: 'active', createdAt: DateTime.now())
    ];
    when(() => mockProjRepo.getProjects('org1')).thenAnswer((_) async => mockProjects);
    
    when(() => mockNotifRepo.getNotifications(any())).thenAnswer((_) async => []);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          projectRepositoryProvider.overrideWithValue(mockProjRepo),
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          notificationRepositoryProvider.overrideWithValue(mockNotifRepo),
        ],
        child: const TaskFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify we are on the login screen
    expect(find.text('TaskFlow Login'), findsOneWidget);

    // Enter credentials
    await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Should navigate to dashboard
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Project 1'), findsOneWidget);
  });
}
