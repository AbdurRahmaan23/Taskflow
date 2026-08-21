import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/data_sources/mock_data_source.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/models/models.dart';
import '../../data/services/local_cache_service.dart';
import '../../data/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Injected in main.dart
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService(ref.watch(sharedPreferencesProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(sharedPreferencesProvider));
});

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
  bool isOffline = false;

  @override
  Future<List<Project>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return [];
    
    try {
      final projects = await ref.watch(projectRepositoryProvider).getProjects(user.orgId);
      ref.read(localCacheServiceProvider).cacheProjects(projects);
      isOffline = false;
      
      // Fire and forget sync if online
      _syncPendingOperations();
      
      return projects;
    } catch (e) {
      final cached = ref.read(localCacheServiceProvider).getCachedProjects();
      if (cached != null) {
        isOffline = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _syncPendingOperations() async {
    final syncSvc = ref.read(syncServiceProvider);
    final queue = syncSvc.getQueue();
    if (queue.isEmpty) return;

    for (final op in queue) {
      try {
        if (op.action == SyncAction.createProject) {
          await ref.read(projectRepositoryProvider).createProject(Project.fromJson(op.payload));
        } else if (op.action == SyncAction.updateProject) {
          await ref.read(projectRepositoryProvider).updateProject(Project.fromJson(op.payload));
        } else if (op.action == SyncAction.deleteProject) {
          await ref.read(projectRepositoryProvider).deleteProject(op.payload['id']);
        } else if (op.action == SyncAction.createTask) {
          await ref.read(taskRepositoryProvider).createTask(Task.fromJson(op.payload));
        } else if (op.action == SyncAction.updateTask) {
          await ref.read(taskRepositoryProvider).updateTask(Task.fromJson(op.payload));
        } else if (op.action == SyncAction.deleteTask) {
          await ref.read(taskRepositoryProvider).deleteTask(op.payload['id']);
        }
        await syncSvc.removeFromQueue(op.id);
      } catch (e) {
        // If it fails, leave it in the queue for later
      }
    }
  }

  Future<void> createProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(projectRepositoryProvider).createProject(project);
      } catch (e) {
        // Offline mutation
        final cache = ref.read(localCacheServiceProvider);
        final syncSvc = ref.read(syncServiceProvider);
        
        await syncSvc.addToQueue(PendingOperation(
          id: project.id,
          action: SyncAction.createProject,
          payload: project.toJson(),
        ));
        
        final current = cache.getCachedProjects() ?? [];
        current.add(project);
        await cache.cacheProjects(current);
        isOffline = true;
      }
      
      try {
        final projects = await ref.read(projectRepositoryProvider).getProjects(ref.read(authStateProvider).value!.orgId);
        ref.read(localCacheServiceProvider).cacheProjects(projects);
        isOffline = false;
        return projects;
      } catch (e) {
        return ref.read(localCacheServiceProvider).getCachedProjects() ?? [];
      }
    });
  }

  Future<void> updateProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(projectRepositoryProvider).updateProject(project);
      } catch (e) {
        // Offline mutation
        final cache = ref.read(localCacheServiceProvider);
        final syncSvc = ref.read(syncServiceProvider);
        
        await syncSvc.addToQueue(PendingOperation(
          id: project.id,
          action: SyncAction.updateProject,
          payload: project.toJson(),
        ));
        
        final current = cache.getCachedProjects() ?? [];
        final idx = current.indexWhere((p) => p.id == project.id);
        if (idx != -1) {
          current[idx] = project;
          await cache.cacheProjects(current);
        }
        isOffline = true;
      }
      
      try {
        final projects = await ref.read(projectRepositoryProvider).getProjects(ref.read(authStateProvider).value!.orgId);
        ref.read(localCacheServiceProvider).cacheProjects(projects);
        isOffline = false;
        return projects;
      } catch (e) {
        return ref.read(localCacheServiceProvider).getCachedProjects() ?? [];
      }
    });
  }

  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(projectId);
      } catch (e) {
        // Offline mutation
        final cache = ref.read(localCacheServiceProvider);
        final syncSvc = ref.read(syncServiceProvider);
        
        await syncSvc.addToQueue(PendingOperation(
          id: projectId,
          action: SyncAction.deleteProject,
          payload: {'id': projectId},
        ));
        
        final current = cache.getCachedProjects() ?? [];
        current.removeWhere((p) => p.id == projectId);
        await cache.cacheProjects(current);
        isOffline = true;
      }
      
      try {
        final projects = await ref.read(projectRepositoryProvider).getProjects(ref.read(authStateProvider).value!.orgId);
        ref.read(localCacheServiceProvider).cacheProjects(projects);
        isOffline = false;
        return projects;
      } catch (e) {
        return ref.read(localCacheServiceProvider).getCachedProjects() ?? [];
      }
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
  bool isOffline = false;

  @override
  Future<List<Task>> build(String arg) async {
    try {
      final tasks = await ref.watch(taskRepositoryProvider).getTasks(arg);
      ref.read(localCacheServiceProvider).cacheTasks(arg, tasks);
      isOffline = false;
      return tasks;
    } catch (e) {
      final cached = ref.read(localCacheServiceProvider).getCachedTasks(arg);
      if (cached != null) {
        isOffline = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(taskRepositoryProvider).createTask(task);
      } catch (e) {
        final cache = ref.read(localCacheServiceProvider);
        final syncSvc = ref.read(syncServiceProvider);
        
        await syncSvc.addToQueue(PendingOperation(
          id: task.id,
          action: SyncAction.createTask,
          payload: task.toJson(),
        ));
        
        final current = cache.getCachedTasks(arg) ?? [];
        current.add(task);
        await cache.cacheTasks(arg, current);
        isOffline = true;
      }

      try {
        final tasks = await ref.read(taskRepositoryProvider).getTasks(arg);
        ref.read(localCacheServiceProvider).cacheTasks(arg, tasks);
        isOffline = false;
        return tasks;
      } catch (e) {
        return ref.read(localCacheServiceProvider).getCachedTasks(arg) ?? [];
      }
    });
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(taskRepositoryProvider).updateTask(task);
      } catch (e) {
        final cache = ref.read(localCacheServiceProvider);
        final syncSvc = ref.read(syncServiceProvider);
        
        await syncSvc.addToQueue(PendingOperation(
          id: task.id,
          action: SyncAction.updateTask,
          payload: task.toJson(),
        ));
        
        final current = cache.getCachedTasks(arg) ?? [];
        final idx = current.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          current[idx] = task;
          await cache.cacheTasks(arg, current);
        }
        isOffline = true;
      }

      try {
        final tasks = await ref.read(taskRepositoryProvider).getTasks(arg);
        ref.read(localCacheServiceProvider).cacheTasks(arg, tasks);
        isOffline = false;
        return tasks;
      } catch (e) {
        return ref.read(localCacheServiceProvider).getCachedTasks(arg) ?? [];
      }
    });
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(taskRepositoryProvider).deleteTask(taskId);
      } catch (e) {
        final cache = ref.read(localCacheServiceProvider);
        final syncSvc = ref.read(syncServiceProvider);
        
        await syncSvc.addToQueue(PendingOperation(
          id: taskId,
          action: SyncAction.deleteTask,
          payload: {'id': taskId, 'projectId': arg},
        ));
        
        final current = cache.getCachedTasks(arg) ?? [];
        current.removeWhere((t) => t.id == taskId);
        await cache.cacheTasks(arg, current);
        isOffline = true;
      }

      try {
        final tasks = await ref.read(taskRepositoryProvider).getTasks(arg);
        ref.read(localCacheServiceProvider).cacheTasks(arg, tasks);
        isOffline = false;
        return tasks;
      } catch (e) {
        return ref.read(localCacheServiceProvider).getCachedTasks(arg) ?? [];
      }
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

// Theme Mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(_prefs.getBool('isDarkMode') ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool('isDarkMode', state);
  }
}
