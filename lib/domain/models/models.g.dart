// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Organization _$OrganizationFromJson(Map<String, dynamic> json) =>
    _Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OrganizationToJson(_Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
    };

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatar_url'] as String,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'avatar_url': instance.avatarUrl,
};

_OrgMember _$OrgMemberFromJson(Map<String, dynamic> json) => _OrgMember(
  orgId: json['org_id'] as String,
  userId: json['user_id'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$OrgMemberToJson(_OrgMember instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'user_id': instance.userId,
      'role': instance.role,
    };

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  id: json['id'] as String,
  orgId: json['org_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  taskCount: (json['task_count'] as num).toInt(),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'name': instance.name,
  'description': instance.description,
  'task_count': instance.taskCount,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
};

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  projectId: json['project_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  status: json['status'] as String,
  priority: json['priority'] as String,
  assigneeId: json['assignee_id'] as String?,
  dueDate: json['due_date'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'project_id': instance.projectId,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'priority': instance.priority,
  'assignee_id': instance.assigneeId,
  'due_date': instance.dueDate,
  'created_at': instance.createdAt.toIso8601String(),
};

_AuthCredentials _$AuthCredentialsFromJson(Map<String, dynamic> json) =>
    _AuthCredentials(
      email: json['email'] as String,
      password: json['password'] as String,
      orgId: json['org_id'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$AuthCredentialsToJson(_AuthCredentials instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'org_id': instance.orgId,
      'role': instance.role,
    };

_MockLoginResponse _$MockLoginResponseFromJson(Map<String, dynamic> json) =>
    _MockLoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresIn: (json['access_token_expires_in_seconds'] as num)
          .toInt(),
      refreshTokenExpiresIn: (json['refresh_token_expires_in_seconds'] as num)
          .toInt(),
    );

Map<String, dynamic> _$MockLoginResponseToJson(_MockLoginResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'access_token_expires_in_seconds': instance.accessTokenExpiresIn,
      'refresh_token_expires_in_seconds': instance.refreshTokenExpiresIn,
    };

_Comment _$CommentFromJson(Map<String, dynamic> json) => _Comment(
  id: json['id'] as String,
  taskId: json['task_id'] as String,
  userId: json['user_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CommentToJson(_Comment instance) => <String, dynamic>{
  'id': instance.id,
  'task_id': instance.taskId,
  'user_id': instance.userId,
  'content': instance.content,
  'created_at': instance.createdAt.toIso8601String(),
};

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      isRead: json['read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'task_id': instance.taskId,
      'type': instance.type,
      'message': instance.message,
      'read': instance.isRead,
      'created_at': instance.createdAt.toIso8601String(),
    };
