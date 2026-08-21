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
  final _commentController = TextEditingController();

  Future<void> _updateStatus(Task task, String newStatus) async {
    final updated = task.copyWith(status: newStatus);
    await ref.read(tasksProvider(task.projectId).notifier).updateTask(updated);
    ref.invalidate(taskProvider(task.id));
    if (mounted) {
      final error = ref.read(tasksProvider(task.projectId)).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _updateAssignee(Task task, String? newAssigneeId) async {
    final updated = task.copyWith(assigneeId: newAssigneeId);
    await ref.read(tasksProvider(task.projectId).notifier).updateTask(updated);
    ref.invalidate(taskProvider(task.id));
    if (mounted) {
      final error = ref.read(tasksProvider(task.projectId)).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskProvider(widget.taskId));
    final orgMembersAsync = ref.watch(orgMembersProvider);
    final orgMembers = orgMembersAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (taskAsync.value != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditTaskDialog(context, taskAsync.value!),
            ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (task) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(task.description),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Text('Status: '),
                  DropdownButton<String>(
                    value: task.status,
                    items: ['todo', 'in_progress', 'review', 'done']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _updateStatus(task, val);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Text('Assignee: '),
              DropdownButton<String?>(
                value: task.assigneeId,
                hint: const Text('Unassigned'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                  ...orgMembers.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.name)))
                ],
                onChanged: (val) => _updateAssignee(task, val),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final commentsAsync = ref.watch(commentsProvider(widget.taskId));
                    return commentsAsync.when(
                      data: (comments) {
                        if (comments.isEmpty) return const Center(child: Text('No comments yet.'));
                        return ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final c = comments[index];
                            return ListTile(
                              title: Text(c.content),
                              subtitle: Text('By ${c.userId} on ${c.createdAt.toLocal().toString().split('.')[0]}'),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    );
                  },
                ),
              ),
              Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_commentController.text.trim().isEmpty) return;
                    final auth = ref.read(authStateProvider).value;
                    if (auth == null) return;
                    
                    final newComment = Comment(
                      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
                      taskId: widget.taskId,
                      userId: auth.email, // using email as a simple user ID reference for mock
                      content: _commentController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await ref.read(taskRepositoryProvider).createComment(newComment);
                    _commentController.clear();
                    ref.invalidate(commentsProvider(widget.taskId));
                  },
                )
              ],
            )
          ],
        ),
      ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    String selectedPriority = task.priority;
    DateTime? selectedDueDate = task.dueDate != null ? DateTime.tryParse(task.dueDate!) : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
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
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
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
                    final updated = task.copyWith(
                      title: titleController.text,
                      description: descController.text,
                      priority: selectedPriority,
                      dueDate: selectedDueDate?.toIso8601String(),
                    );
                    await ref.read(tasksProvider(task.projectId).notifier).updateTask(updated);
                    ref.invalidate(taskProvider(task.id));
                    if (context.mounted) {
                      final error = ref.read(tasksProvider(task.projectId)).error;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
