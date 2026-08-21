import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../data_sources/mock_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockDataSource dataSource;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl(this.dataSource, this.secureStorage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _currentUserKey = 'current_user';

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
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  @override
  Future<String?> getAccessToken() async {
    return secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<void> saveTokens(MockLoginResponse response) async {
    await secureStorage.write(key: _accessTokenKey, value: response.accessToken);
    await secureStorage.write(key: _refreshTokenKey, value: response.refreshToken);
  }

  @override
  Future<AuthCredentials> getCurrentUser() async {
    final userJson = await secureStorage.read(key: _currentUserKey);
    if (userJson == null) throw Exception('No user found');
    return AuthCredentials.fromJson(jsonDecode(userJson));
  }
}

class ProjectRepositoryImpl implements ProjectRepository {
  final MockDataSource dataSource;

  ProjectRepositoryImpl(this.dataSource);

  @override
  Future<List<Project>> getProjects(String orgId) => dataSource.getProjects(orgId);

  @override
  Future<Project> getProjectById(String projectId) async {
    final projects = await dataSource.getProjects(''); // Needs optimization, but it's mock
    // Wait, MockDataSource filters by orgId. Let's add getProjectById to MockDataSource, or just fetch all and find it.
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Project> createProject(Project project) => dataSource.createProject(project);

  @override
  Future<Project> updateProject(Project project) => dataSource.updateProject(project);

  @override
  Future<void> deleteProject(String projectId) => dataSource.deleteProject(projectId);
}

class TaskRepositoryImpl implements TaskRepository {
  final MockDataSource dataSource;

  TaskRepositoryImpl(this.dataSource);

  @override
  Future<List<Task>> getTasks(String projectId) => dataSource.getTasks(projectId);

  @override
  Future<Task> getTaskById(String taskId) {
    throw UnimplementedError('Not implemented yet');
  }

  @override
  Future<Task> createTask(Task task) => dataSource.createTask(task);

  @override
  Future<Task> updateTask(Task task) => dataSource.updateTask(task);

  @override
  Future<void> deleteTask(String taskId) => dataSource.deleteTask(taskId);
}

class UserRepositoryImpl implements UserRepository {
  final MockDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<List<User>> getUsers() => dataSource.getUsers();

  @override
  Future<List<OrgMember>> getOrgMembers(String orgId) => dataSource.getOrgMembers(orgId);
}
