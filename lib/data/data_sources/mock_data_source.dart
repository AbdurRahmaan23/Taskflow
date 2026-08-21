import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/models.dart';

class CancelToken {
  bool isCancelled = false;
  void cancel() => isCancelled = true;
}

class MockDataSource {
  Map<String, dynamic>? _data;
  bool simulateNetworkDelay = true;
  bool simulateOffline = false;
  bool simulateError = false;

  Future<void> init() async {
    if (_data != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/mock_data/mock-data.json');
      _data = jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Failed to load mock data: $e');
    }
  }

  Future<void> _simulateDelay([CancelToken? cancelToken]) async {
    if (cancelToken?.isCancelled ?? false) throw Exception('Request Cancelled');
    
    if (simulateOffline) {
      throw Exception('Simulated offline mode: Network is unreachable.');
    }
    if (simulateNetworkDelay) {
      // Small loop to allow cancellation during delay
      for (int i = 0; i < 5; i++) {
        if (cancelToken?.isCancelled ?? false) throw Exception('Request Cancelled');
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    if (cancelToken?.isCancelled ?? false) throw Exception('Request Cancelled');
    if (simulateError) {
      throw Exception('Simulated API Error.');
    }
  }

  Future<Map<String, dynamic>> _getRawData() async {
    await init();
    await _simulateDelay();
    return _data!;
  }

  Future<List<User>> getUsers() async {
    await init();
    await _simulateDelay();
    final List users = _data!['users'] ?? [];
    return users.map((e) => User.fromJson(e)).toList();
  }

  Future<List<Project>> getProjects(String orgId) async {
    await init();
    await _simulateDelay();
    final List projects = _data!['projects'] ?? [];
    return projects
        .map((e) => Project.fromJson(e))
        .where((p) => p.orgId == orgId)
        .toList();
  }

  Future<List<Project>> getRawProjects() async {
    await init();
    await _simulateDelay();
    final List projects = _data!['projects'] ?? [];
    return projects.map((e) => Project.fromJson(e)).toList();
  }

  Future<Project> createProject(Project project) async {
    await init();
    await _simulateDelay();
    _data!['projects'].add(project.toJson());
    return project;
  }

  Future<Project> updateProject(Project project) async {
    await init();
    await _simulateDelay();
    final index = _data!['projects'].indexWhere((p) => p['id'] == project.id);
    if (index != -1) {
      _data!['projects'][index] = project.toJson();
      return project;
    }
    throw Exception('Project not found');
  }

  Future<void> deleteProject(String projectId) async {
    await init();
    await _simulateDelay();
    _data!['projects'].removeWhere((p) => p['id'] == projectId);
  }

  Future<List<Task>> getTasks(String projectId) async {
    await init();
    await _simulateDelay();
    final List tasks = _data!['tasks'] ?? [];
    return tasks
        .map((e) => Task.fromJson(e))
        .where((t) => t.projectId == projectId)
        .toList();
  }

  Future<Task> getTaskById(String taskId) async {
    await init();
    await _simulateDelay();
    final List tasks = _data!['tasks'] ?? [];
    final t = tasks.firstWhere((e) => e['id'] == taskId, orElse: () => throw Exception('Task not found'));
    return Task.fromJson(t);
  }

  Future<Task> createTask(Task task) async {
    await init();
    await _simulateDelay();
    _data!['tasks'].add(task.toJson());
    return task;
  }

  Future<Task> updateTask(Task task) async {
    await init();
    await _simulateDelay();
    final index = _data!['tasks'].indexWhere((t) => t['id'] == task.id);
    if (index != -1) {
      _data!['tasks'][index] = task.toJson();
      return task;
    }
    throw Exception('Task not found');
  }

  Future<void> deleteTask(String taskId) async {
    await init();
    await _simulateDelay();
    _data!['tasks'].removeWhere((t) => t['id'] == taskId);
  }
  
  Future<List<OrgMember>> getOrgMembers(String orgId) async {
    await init();
    await _simulateDelay();
    final List members = _data!['org_members'] ?? [];
    return members
        .map((e) => OrgMember.fromJson(e))
        .where((m) => m.orgId == orgId)
        .toList();
  }

  Future<MockLoginResponse> login(String email, String password) async {
    await init();
    await _simulateDelay();
    
    final authMock = _data!['auth_mock'];
    final List credentials = authMock['test_credentials'];
    
    for (var cred in credentials) {
      if (cred['email'] == email && cred['password'] == password) {
        return MockLoginResponse.fromJson(authMock['mock_login_response']);
      }
    }
    throw Exception('Invalid email or password');
  }

  Future<MockLoginResponse> refreshToken(String refreshToken) async {
    await init();
    await _simulateDelay();
    
    // Simulate finding a matching refresh token
    // In mock data, there's only one token response, so we'll just return it.
    // In a real scenario, this would validate the token first.
    return MockLoginResponse.fromJson(_data!['auth_mock']['mock_login_response']);
  }
  
  Future<AuthCredentials> getUserCredentials(String email) async {
    await init();
    final authMock = _data!['auth_mock'];
    final List credentials = authMock['test_credentials'];
    
    for (var cred in credentials) {
      if (cred['email'] == email) {
        return AuthCredentials.fromJson(cred);
      }
    }
    throw Exception('User not found');
  }

  Future<List<Comment>> getComments(String taskId) async {
    await init();
    await _simulateDelay();
    final List comments = _data!['comments'] ?? [];
    return comments
        .map((e) => Comment.fromJson(e))
        .where((c) => c.taskId == taskId)
        .toList();
  }

  Future<Comment> createComment(Comment comment) async {
    await init();
    await _simulateDelay();
    _data!['comments'].add(comment.toJson());
    return comment;
  }

  Future<List<AppNotification>> getNotifications(String userId) async {
    await init();
    await _simulateDelay();
    final List notifs = _data!['notifications'] ?? [];
    return notifs
        .map((e) => AppNotification.fromJson(e))
        .where((n) => n.userId == userId)
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await init();
    await _simulateDelay();
    final index = _data!['notifications'].indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _data!['notifications'][index]['is_read'] = true;
    }
  }
}
