import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/data_sources/mock_data_source.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/models/models.dart';

// Global Data Source
final mockDataSourceProvider = Provider<MockDataSource>((ref) {
  return MockDataSource();
});

// Secure Storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(mockDataSourceProvider), ref.watch(secureStorageProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(ref.watch(mockDataSourceProvider), ref.watch(authRepositoryProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    ref.watch(mockDataSourceProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(mockDataSourceProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(mockDataSourceProvider));
});

// State Management: Auth State
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthCredentials?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthCredentials?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final authenticated = await _authRepository.authenticateWithBiometrics();
        if (authenticated) {
          final user = await _authRepository.getCurrentUser();
          state = AsyncValue.data(user);
        } else {
          // If biometric fails or is cancelled, log out
          await _authRepository.logout();
          state = const AsyncValue.data(null);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.login(email, password);
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// State Management: Projects
final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(() {
  return ProjectsNotifier();
});

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return [];
    return ref.watch(projectRepositoryProvider).getProjects(user.orgId);
  }

  Future<void> createProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(projectRepositoryProvider).createProject(project);
      return ref.read(projectRepositoryProvider).getProjects(ref.read(authStateProvider).value!.orgId);
    });
  }

  Future<void> updateProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(projectRepositoryProvider).updateProject(project);
      return ref.read(projectRepositoryProvider).getProjects(ref.read(authStateProvider).value!.orgId);
    });
  }

  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(projectRepositoryProvider).deleteProject(projectId);
      return ref.read(projectRepositoryProvider).getProjects(ref.read(authStateProvider).value!.orgId);
    });
  }
}

// State Management: Org Members
final orgMembersProvider = FutureProvider<List<User>>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return [];
      final repo = ref.watch(userRepositoryProvider);
      return repo.getOrgMembers(user.orgId);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// State Management: Tasks for a project
final tasksProvider = AsyncNotifierProviderFamily<TasksNotifier, List<Task>, String>(() {
  return TasksNotifier();
});

class TasksNotifier extends FamilyAsyncNotifier<List<Task>, String> {
  @override
  Future<List<Task>> build(String arg) async {
    return ref.watch(taskRepositoryProvider).getTasks(arg);
  }

  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).createTask(task);
      return ref.read(taskRepositoryProvider).getTasks(arg);
    });
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).updateTask(task);
      return ref.read(taskRepositoryProvider).getTasks(arg);
    });
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).deleteTask(taskId);
      return ref.read(taskRepositoryProvider).getTasks(arg);
    });
  }
}

final taskProvider = FutureProvider.family<Task, String>((ref, taskId) async {
  return ref.watch(taskRepositoryProvider).getTaskById(taskId);
});

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getComments(taskId);
});

final notificationsProvider = FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications(userId);
});

// Toggles for testing errors & offline
final debugOfflineProvider = StateProvider<bool>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  return dataSource.simulateOffline;
});

final debugErrorProvider = StateProvider<bool>((ref) {
  final dataSource = ref.watch(mockDataSourceProvider);
  return dataSource.simulateError;
});
