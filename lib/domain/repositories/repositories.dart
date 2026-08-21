import '../models/models.dart';

abstract class AuthRepository {
  Future<MockLoginResponse> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getAccessToken();
  Future<void> saveTokens(MockLoginResponse response);
  Future<AuthCredentials> getCurrentUser();
}

abstract class ProjectRepository {
  Future<List<Project>> getProjects(String orgId);
  Future<Project> getProjectById(String projectId);
  Future<Project> createProject(Project project);
  Future<Project> updateProject(Project project);
  Future<void> deleteProject(String projectId);
}

abstract class TaskRepository {
  Future<List<Task>> getTasks(String projectId);
  Future<Task> getTaskById(String taskId);
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<List<Comment>> getComments(String taskId);
  Future<Comment> createComment(Comment comment);
}

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
}

abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<List<OrgMember>> getOrgMembers(String orgId);
}
