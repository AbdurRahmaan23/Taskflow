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
  return TaskRepositoryImpl(ref.watch(mockDataSourceProvider));
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
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return [];
      final repo = ref.watch(projectRepositoryProvider);
      return repo.getProjects(user.orgId);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// State Management: Org Members
final orgMembersProvider = FutureProvider<List<OrgMember>>((ref) async {
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
final tasksProvider = FutureProvider.family<List<Task>, String>((ref, projectId) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTasks(projectId);
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
