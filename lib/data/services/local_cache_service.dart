import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/models.dart';

class LocalCacheService {
  static const _projectsKey = 'cached_projects';
  static const _tasksPrefix = 'cached_tasks_';

  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  Future<void> cacheProjects(List<Project> projects) async {
    final jsonList = projects.map((p) => p.toJson()).toList();
    await _prefs.setString(_projectsKey, jsonEncode(jsonList));
  }

  List<Project>? getCachedProjects() {
    final jsonString = _prefs.getString(_projectsKey);
    if (jsonString == null) return null;
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => Project.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheTasks(String projectId, List<Task> tasks) async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await _prefs.setString('$_tasksPrefix$projectId', jsonEncode(jsonList));
  }

  List<Task>? getCachedTasks(String projectId) {
    final jsonString = _prefs.getString('$_tasksPrefix$projectId');
    if (jsonString == null) return null;
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => Task.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }
}
