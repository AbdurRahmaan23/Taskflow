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
  String? _filterAssignee;
  DateTime? _filterDueDate;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(widget.projectId));
    final membersAsync = ref.watch(orgMembersProvider);
    final members = membersAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Tasks'),
      ),
      body: Column(
        children: [
          _buildFilterRow(members),
          Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  final isOfflineData = ref.read(tasksProvider(widget.projectId).notifier).isOffline;
                  
                  var filtered = tasks;
                  if (_filterStatus != null && _filterStatus!.isNotEmpty) {
                    filtered = filtered.where((t) => t.status == _filterStatus).toList();
                  }
                  if (_filterPriority != null && _filterPriority!.isNotEmpty) {
                    filtered = filtered.where((t) => t.priority == _filterPriority).toList();
                  }
                  if (_filterAssignee != null && _filterAssignee!.isNotEmpty) {
                    filtered = filtered.where((t) => t.assigneeId == _filterAssignee).toList();
                  }
                  if (_filterDueDate != null) {
                    filtered = filtered.where((t) {
                      if (t.dueDate == null) return false;
                      final due = DateTime.tryParse(t.dueDate!);
                      if (due == null) return false;
                      return due.year == _filterDueDate!.year &&
                             due.month == _filterDueDate!.month &&
                             due.day == _filterDueDate!.day;
                    }).toList();
                  }

                  Widget content;
                  if (filtered.isEmpty) {
                    content = const Center(child: Text('No tasks found.'));
                  } else {
                    final todoTasks = filtered.where((t) => t.status == 'todo').toList();
                    final inProgressTasks = filtered.where((t) => t.status == 'in_progress').toList();
                    final reviewTasks = filtered.where((t) => t.status == 'review').toList();
                    final doneTasks = filtered.where((t) => t.status == 'done').toList();

                    content = ListView(
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
                        _buildTaskSection('To Do', todoTasks, members, context),
                        _buildTaskSection('In Progress', inProgressTasks, members, context),
                        _buildTaskSection('Review', reviewTasks, members, context),
                        _buildTaskSection('Done', doneTasks, members, context),
                      ],
                    );
                  }

                  Widget mainWidget = RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(tasksProvider(widget.projectId));
                      await ref.read(tasksProvider(widget.projectId).future);
                    },
                    child: content,
                  );

                  if (isOfflineData) {
                    return Column(
                      children: [
                        Container(
                          color: Colors.orange,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          child: const Text('⚠️ Offline Mode - Displaying cached tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                        Expanded(child: mainWidget),
                      ],
                    );
                  }

                  return mainWidget;
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Error: $err', textAlign: TextAlign.center),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(tasksProvider(widget.projectId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildFilterRow(List<User> members) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status', isDense: true),
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All')),
                    DropdownMenuItem<String?>(value: 'todo', child: Text('To Do')),
                    DropdownMenuItem<String?>(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem<String?>(value: 'review', child: Text('Review')),
                    DropdownMenuItem<String?>(value: 'done', child: Text('Done')),
                  ],
                  onChanged: (val) => setState(() => _filterStatus = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Priority', isDense: true),
                  value: _filterPriority,
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All')),
                    DropdownMenuItem<String?>(value: 'low', child: Text('Low')),
                    DropdownMenuItem<String?>(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem<String?>(value: 'high', child: Text('High')),
                    DropdownMenuItem<String?>(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (val) => setState(() => _filterPriority = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Assignee', isDense: true),
                  value: _filterAssignee,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All')),
                    ...members.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.name)))
                  ],
                  onChanged: (val) => setState(() => _filterAssignee = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _filterDueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _filterDueDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      isDense: true,
                      suffixIcon: _filterDueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _filterDueDate = null),
                            )
                          : null,
                    ),
                    child: Text(_filterDueDate != null ? _filterDueDate!.toString().split(' ')[0] : 'All'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Task'),
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text(selectedDueDate == null ? 'No due date' : 'Due: ${selectedDueDate.toString().split(' ')[0]}')),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDueDate = picked);
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      dueDate: selectedDueDate?.toIso8601String(),
                      createdAt: DateTime.now(),
                    );
                    await ref.read(tasksProvider(widget.projectId).notifier).createTask(newTask);
                    if (context.mounted) {
                      final error = ref.read(tasksProvider(widget.projectId)).error;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                      } else {
                        Navigator.pop(context);
                      }
                    }
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

  Widget _buildTaskSection(String title, List<Task> tasks, List<User> members, BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ...tasks.map((task) {
          final assignee = members.where((m) => m.id == task.assigneeId).firstOrNull?.name ?? task.assigneeId ?? 'Unassigned';
          return ListTile(
            title: Text(task.title),
            subtitle: Text('Priority: ${task.priority} | Assignee: $assignee${task.dueDate != null ? ' | Due: ${task.dueDate!.split('T')[0]}' : ''}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await ref.read(tasksProvider(widget.projectId).notifier).deleteTask(task.id);
                if (context.mounted) {
                  final error = ref.read(tasksProvider(widget.projectId)).error;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
            ),
            onTap: () {
              context.push('/task/${task.id}');
            },
          );
        }),
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
