import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class Organization with _$Organization {
  const factory Organization({
    required String id,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Organization;

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);
}

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'avatar_url') required String avatarUrl,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class OrgMember with _$OrgMember {
  const factory OrgMember({
    @JsonKey(name: 'org_id') required String orgId,
    @JsonKey(name: 'user_id') required String userId,
    required String role,
  }) = _OrgMember;

  factory OrgMember.fromJson(Map<String, dynamic> json) => _$OrgMemberFromJson(json);
}

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    @JsonKey(name: 'org_id') required String orgId,
    required String name,
    required String description,
    @JsonKey(name: 'task_count') required int taskCount,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}

@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    required String title,
    required String description,
    required String status,
    required String priority,
    @JsonKey(name: 'assignee_id') String? assigneeId,
    @JsonKey(name: 'due_date') String? dueDate,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

@freezed
abstract class AuthCredentials with _$AuthCredentials {
  const factory AuthCredentials({
    required String email,
    required String password,
    @JsonKey(name: 'org_id') required String orgId,
    required String role,
  }) = _AuthCredentials;

  factory AuthCredentials.fromJson(Map<String, dynamic> json) => _$AuthCredentialsFromJson(json);
}

@freezed
abstract class MockLoginResponse with _$MockLoginResponse {
  const factory MockLoginResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'access_token_expires_in_seconds') required int accessTokenExpiresIn,
    @JsonKey(name: 'refresh_token_expires_in_seconds') required int refreshTokenExpiresIn,
  }) = _MockLoginResponse;

  factory MockLoginResponse.fromJson(Map<String, dynamic> json) => _$MockLoginResponseFromJson(json);
}

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required String id,
    @JsonKey(name: 'task_id') required String taskId,
    @JsonKey(name: 'user_id') required String userId,
    required String content,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    required String message,
    @JsonKey(name: 'is_read') required bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}
