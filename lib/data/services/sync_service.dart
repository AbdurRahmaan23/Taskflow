import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncAction {
  createProject,
  updateProject,
  deleteProject,
  createTask,
  updateTask,
  deleteTask,
}

class PendingOperation {
  final String id;
  final SyncAction action;
  final Map<String, dynamic> payload;

  PendingOperation({
    required this.id,
    required this.action,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.name,
        'payload': payload,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      action: SyncAction.values.firstWhere((e) => e.name == json['action']),
      payload: json['payload'],
    );
  }
}

class SyncService {
  static const _queueKey = 'sync_queue';
  final SharedPreferences _prefs;

  SyncService(this._prefs);

  List<PendingOperation> getQueue() {
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString == null) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => PendingOperation.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addToQueue(PendingOperation op) async {
    final queue = getQueue();
    queue.add(op);
    await _saveQueue(queue);
  }

  Future<void> removeFromQueue(String id) async {
    final queue = getQueue();
    queue.removeWhere((op) => op.id == id);
    await _saveQueue(queue);
  }
  
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  Future<void> _saveQueue(List<PendingOperation> queue) async {
    final jsonList = queue.map((e) => e.toJson()).toList();
    await _prefs.setString(_queueKey, jsonEncode(jsonList));
  }
}
