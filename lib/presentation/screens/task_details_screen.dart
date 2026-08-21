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
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final auth = ref.read(authStateProvider).value;
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
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditTaskDialog(context),
          ),
        ],
      ),
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
    );
  }

  void _showEditTaskDialog(BuildContext context) {
    if (task == null) return;
    
    final titleController = TextEditingController(text: task!.title);
    final descController = TextEditingController(text: task!.description);
    String selectedPriority = task!.priority;
    DateTime? selectedDueDate = task!.dueDate != null ? DateTime.tryParse(task!.dueDate!) : null;

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
                    this.setState(() => isLoading = true);
                    final updated = task!.copyWith(
                      title: titleController.text,
                      description: descController.text,
                      priority: selectedPriority,
                      dueDate: selectedDueDate?.toIso8601String(),
                    );
                    await ref.read(taskRepositoryProvider).updateTask(updated);
                    ref.invalidate(tasksProvider(updated.projectId));
                    task = updated;
                    this.setState(() => isLoading = false);
                    if (context.mounted) Navigator.pop(context);
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
