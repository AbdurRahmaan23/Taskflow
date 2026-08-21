import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/models.dart';
import '../providers/providers.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  String? _filterStatus;
  String? _filterPriority;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Tasks'),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                // Apply filters
                var filtered = tasks;
                if (_filterStatus != null && _filterStatus!.isNotEmpty) {
                  filtered = filtered.where((t) => t.status == _filterStatus).toList();
                }
                if (_filterPriority != null && _filterPriority!.isNotEmpty) {
                  filtered = filtered.where((t) => t.priority == _filterPriority).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No tasks found.'));
                }

                final todoTasks = filtered.where((t) => t.status == 'todo').toList();
                final inProgressTasks = filtered.where((t) => t.status == 'in_progress').toList();
                final reviewTasks = filtered.where((t) => t.status == 'review').toList();
                final doneTasks = filtered.where((t) => t.status == 'done').toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tasksProvider(widget.projectId));
                    await ref.read(tasksProvider(widget.projectId).future);
                  },
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSummaryCard('To Do', todoTasks.length, Colors.blue),
                            _buildSummaryCard('In Progress', inProgressTasks.length, Colors.orange),
                            _buildSummaryCard('Review', reviewTasks.length, Colors.purple),
                            _buildSummaryCard('Done', doneTasks.length, Colors.green),
                          ],
                        ),
                      ),
                      _buildTaskSection('To Do', todoTasks, context),
                      _buildTaskSection('In Progress', inProgressTasks, context),
                      _buildTaskSection('Review', reviewTasks, context),
                      _buildTaskSection('Done', doneTasks, context),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context, ref),
        child: const Icon(Icons.add_task),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              decoration: const InputDecoration(labelText: 'Status', isDense: true),
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'todo', child: Text('To Do')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'review', child: Text('Review')),
                DropdownMenuItem(value: 'done', child: Text('Done')),
              ],
              onChanged: (val) => setState(() => _filterStatus = val),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String?>(
              decoration: const InputDecoration(labelText: 'Priority', isDense: true),
              value: _filterPriority,
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (val) => setState(() => _filterPriority = val),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['low', 'medium', 'high', 'urgent'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => selectedPriority = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final newTask = Task(
                      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                      projectId: widget.projectId,
                      title: titleController.text,
                      description: descController.text,
                      status: 'todo',
                      priority: selectedPriority,
                      createdAt: DateTime.now(),
                    );
                    await ref.read(taskRepositoryProvider).createTask(newTask);
                    ref.invalidate(tasksProvider(widget.projectId));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks, BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ...tasks.map((task) => ListTile(
          title: Text(task.title),
          subtitle: Text('Priority: ${task.priority} | Assignee: ${task.assigneeId ?? 'Unassigned'}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await ref.read(taskRepositoryProvider).deleteTask(task.id);
              ref.invalidate(tasksProvider(widget.projectId));
            },
          ),
          onTap: () {
            context.push('/task/${task.id}');
          },
        )),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
