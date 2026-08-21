import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../data_sources/mock_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockDataSource dataSource;
  final FlutterSecureStorage secureStorage;
  final LocalAuthentication auth = LocalAuthentication();

  AuthRepositoryImpl(this.dataSource, this.secureStorage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _currentUserKey = 'current_user';
  static const _tokenIssuedAtKey = 'token_issued_at';

  @override
  Future<MockLoginResponse> login(String email, String password) async {
    final response = await dataSource.login(email, password);
    final userCredentials = await dataSource.getUserCredentials(email);
    
    await saveTokens(response);
    await secureStorage.write(key: _currentUserKey, value: jsonEncode(userCredentials.toJson()));
    
    return response;
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: _currentUserKey);
    await secureStorage.delete(key: _tokenIssuedAtKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  @override
  Future<String?> getAccessToken() async {
    final token = await secureStorage.read(key: _accessTokenKey);
    if (token == null) return null;

    final issuedAtStr = await secureStorage.read(key: _tokenIssuedAtKey);
    if (issuedAtStr != null) {
      final issuedAt = DateTime.parse(issuedAtStr);
      final now = DateTime.now();
      // Simulate 15 min expiry
      if (now.difference(issuedAt).inMinutes >= 15) {
        try {
          final newResponse = await refreshToken();
          return newResponse.accessToken;
        } catch (e) {
          await logout();
          return null;
        }
      }
    }
    return token;
  }

  @override
  Future<void> saveTokens(MockLoginResponse response) async {
    await secureStorage.write(key: _accessTokenKey, value: response.accessToken);
    await secureStorage.write(key: _refreshTokenKey, value: response.refreshToken);
    await secureStorage.write(key: _tokenIssuedAtKey, value: DateTime.now().toIso8601String());
  }

  @override
  Future<AuthCredentials> getCurrentUser() async {
    final userJson = await secureStorage.read(key: _currentUserKey);
    if (userJson == null) throw Exception('No user found');
    return AuthCredentials.fromJson(jsonDecode(userJson));
  }

  @override
  Future<MockLoginResponse> refreshToken() async {
    final refToken = await secureStorage.read(key: _refreshTokenKey);
    if (refToken == null) throw Exception('No refresh token');
    final response = await dataSource.refreshToken(refToken);
    await saveTokens(response);
    return response;
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Fallback to success if device doesn't support it

      final authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock TaskFlow',
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }
}

class ProjectRepositoryImpl implements ProjectRepository {
  final MockDataSource dataSource;
  final AuthRepository authRepository;

  ProjectRepositoryImpl(this.dataSource, this.authRepository);

  Future<void> _checkAdmin() async {
    final user = await authRepository.getCurrentUser();
    if (user.role != 'org_admin') {
      throw Exception('Unauthorized: Only org admins can perform this action');
    }
  }

  @override
  Future<List<Project>> getProjects(String orgId) => dataSource.getProjects(orgId);

  @override
  Future<Project> getProjectById(String projectId) async {
    final projects = await dataSource.getProjects(''); // Needs optimization, but it's mock
    // Wait, MockDataSource filters by orgId. Let's add getProjectById to MockDataSource, or just fetch all and find it.
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Project> createProject(Project project) async {
    await _checkAdmin();
    return dataSource.createProject(project);
  }

  @override
  Future<Project> updateProject(Project project) async {
    await _checkAdmin();
    return dataSource.updateProject(project);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _checkAdmin();
    return dataSource.deleteProject(projectId);
  }
}

class TaskRepositoryImpl implements TaskRepository {
  final MockDataSource dataSource;
  final UserRepository userRepository;
  final ProjectRepository projectRepository;

  TaskRepositoryImpl(this.dataSource, this.userRepository, this.projectRepository);

  @override
  Future<List<Task>> getTasks(String projectId) => dataSource.getTasks(projectId);

  @override
  Future<Task> getTaskById(String taskId) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Task> createTask(Task task) => dataSource.createTask(task);

  @override
  Future<Task> updateTask(Task task) async {
    // If assignee is changing or set, validate they belong to the org
    if (task.assigneeId != null) {
      final projects = await projectRepository.getProjects(''); // Get all to find
      // Actually MockDataSource.getProjects filters by orgId. 
      // It's better to fetch the project from dataSource directly.
      final allProjectsRaw = await dataSource.getRawProjects();
      final project = allProjectsRaw.firstWhere((p) => p.id == task.projectId, 
        orElse: () => throw Exception('Project not found'));

      final orgMembers = await userRepository.getOrgMembers(project.orgId);
      final isMember = orgMembers.any((u) => u.id == task.assigneeId || u.email == task.assigneeId);
      
      if (!isMember) {
        throw Exception('User does not belong to this organization');
      }
    }
    return dataSource.updateTask(task);
  }

  @override
  Future<void> deleteTask(String taskId) {
    return dataSource.deleteTask(taskId);
  }

  @override
  Future<List<Comment>> getComments(String taskId) {
    return dataSource.getComments(taskId);
  }

  @override
  Future<Comment> createComment(Comment comment) {
    return dataSource.createComment(comment);
  }
}

class NotificationRepositoryImpl implements NotificationRepository {
  final MockDataSource _dataSource;
  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<AppNotification>> getNotifications(String userId) {
    return _dataSource.getNotifications(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _dataSource.markNotificationRead(notificationId);
  }
}

class UserRepositoryImpl implements UserRepository {
  final MockDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<List<User>> getUsers() => dataSource.getUsers();

  @override
  Future<List<User>> getOrgMembers(String orgId) async {
    final members = await dataSource.getOrgMembers(orgId);
    final users = await dataSource.getUsers();
    
    // Join: Find users whose id or email matches member.userId
    // We map member.userId to user.id or user.email
    final List<User> orgUsers = [];
    for (var member in members) {
      try {
        final user = users.firstWhere((u) => u.id == member.userId || u.email == member.userId);
        orgUsers.add(user);
      } catch (e) {
        // If not found in users.json, skip or add a dummy
        orgUsers.add(User(id: member.userId, name: member.userId, email: member.userId, avatarUrl: ''));
      }
    }
    return orgUsers;
  }
}
