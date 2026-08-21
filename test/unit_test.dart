import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/data/services/local_cache_service.dart';
import 'package:taskflow/data/services/sync_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTaskRepository extends Mock implements TaskRepository {}
class MockProjectRepository extends Mock implements ProjectRepository {}
class MockLocalCacheService extends Mock implements LocalCacheService {}
class MockSyncService extends Mock implements SyncService {}

class FakeTask extends Fake implements Task {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTask());
  });

  group('AuthNotifier Tests', () {
    late MockAuthRepository mockAuthRepo;
    late ProviderContainer container;

    setUp(() async {
      mockAuthRepo = MockAuthRepository();
      
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    test('Initial checkAuth sets data to null if not logged in', () async {
      when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);

      final notifier = container.read(authStateProvider.notifier);
      // Wait for checkAuth
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(authStateProvider).value, isNull);
    });

    test('login successfully sets user state', () async {
      const mockUser = AuthCredentials(email: 'test@test.com', password: '', orgId: 'org1', role: 'member');
      when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => mockAuthRepo.login('test@test.com', 'password')).thenAnswer((_) async => const MockLoginResponse(accessToken: '', refreshToken: '', accessTokenExpiresIn: 0, refreshTokenExpiresIn: 0));
      when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => mockUser);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.login('test@test.com', 'password');

      expect(container.read(authStateProvider).value, mockUser);
    });
  });

  group('TasksNotifier Tests', () {
    late MockTaskRepository mockTaskRepo;
    late MockLocalCacheService mockCache;
    late MockSyncService mockSync;
    late ProviderContainer container;
    
    final mockTasks = [
      Task(id: '1', projectId: 'p1', title: 'Task 1', description: '', status: 'todo', priority: 'high', createdAt: DateTime.now()),
      Task(id: '2', projectId: 'p1', title: 'Task 2', description: '', status: 'done', priority: 'low', createdAt: DateTime.now()),
    ];

    setUp(() async {
      mockTaskRepo = MockTaskRepository();
      mockCache = MockLocalCacheService();
      mockSync = MockSyncService();
      
      when(() => mockCache.getCachedTasks(any())).thenReturn(mockTasks);
      when(() => mockCache.cacheTasks(any(), any())).thenAnswer((_) async {});

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskRepo),
          localCacheServiceProvider.overrideWithValue(mockCache),
          syncServiceProvider.overrideWithValue(mockSync),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    test('fetches tasks successfully', () async {
      when(() => mockTaskRepo.getTasks('p1')).thenAnswer((_) async => mockTasks);
      
      final sub = container.listen(tasksProvider('p1'), (_, __) {});
      
      final asyncValue = await container.read(tasksProvider('p1').future);
      expect(asyncValue.length, 2);
      expect(asyncValue.first.title, 'Task 1');
      
      sub.close();
    });

    test('creates task and updates state', () async {
      when(() => mockTaskRepo.getTasks('p1')).thenAnswer((_) async => mockTasks);
      
      final newTask = Task(id: '3', projectId: 'p1', title: 'Task 3', description: '', status: 'todo', priority: 'medium', createdAt: DateTime.now());
      
      when(() => mockTaskRepo.createTask(any())).thenAnswer((_) async => newTask);
      
      // Initialize provider
      await container.read(tasksProvider('p1').future);
      
      await container.read(tasksProvider('p1').notifier).createTask(newTask);
      
      // Verify createTask was called
      verify(() => mockTaskRepo.createTask(newTask)).called(1);
    });
  });
}
