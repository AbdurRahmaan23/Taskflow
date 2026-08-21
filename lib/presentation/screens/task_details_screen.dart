import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../providers/providers.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  Task? task;
  List<OrgMember>? orgMembers;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final auth = await ref.read(authStateProvider.future);
      if (auth == null) return;
      
      final repo = ref.read(taskRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      
      // A proper getTaskById is needed in the data layer, we will search all tasks in memory for now
      // Or simply refetch from tasksProvider. But we might not have projectId readily available unless we search.
      // For simplicity in mock, let's just get the raw tasks using a workaround or assume we pass it.
      // Wait, mockDataSource doesn't have a simple getTaskById. Let's get it.
      final mockData = ref.read(mockDataSourceProvider);
      
      // Temporary manual find
      final allProjects = await mockData.getProjects(auth.orgId);
      for (var p in allProjects) {
        final tasks = await mockData.getTasks(p.id);
        final found = tasks.where((t) => t.id == widget.taskId).toList();
        if (found.isNotEmpty) {
          task = found.first;
          break;
        }
      }

      if (task != null) {
        orgMembers = await userRepo.getOrgMembers(auth.orgId);
      }
      
    } catch (e) {
      // ignore
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (task == null) return;
    setState(() => isLoading = true);
    final updated = task!.copyWith(status: newStatus);
    await ref.read(taskRepositoryProvider).updateTask(updated);
    ref.invalidate(tasksProvider(updated.projectId)); // refresh lists
    task = updated;
    setState(() => isLoading = false);
  }
  
  Future<void> _updateAssignee(String? newAssigneeId) async {
    if (task == null) return;
    setState(() => isLoading = true);
    final updated = task!.copyWith(assigneeId: newAssigneeId);
    await ref.read(taskRepositoryProvider).updateTask(updated);
    ref.invalidate(tasksProvider(updated.projectId)); // refresh lists
    task = updated;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task!.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(task!.description),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Text('Status: '),
                DropdownButton<String>(
                  value: task!.status,
                  items: ['todo', 'in_progress', 'review', 'done']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _updateStatus(val);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text('Assignee: '),
            DropdownButton<String?>(
              value: task!.assigneeId,
              hint: const Text('Unassigned'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                ...orgMembers?.map((m) => DropdownMenuItem<String?>(value: m.userId, child: Text(m.userId))) ?? []
              ],
              onChanged: _updateAssignee,
            ),
          ],
        ),
      ),
    );
  }
}
