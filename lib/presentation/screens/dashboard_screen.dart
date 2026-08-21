import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/models.dart';
import '../providers/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                _showNotificationsDialog(context, ref, user.email);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectsProvider);
              await ref.read(projectsProvider.future);
            },
              child: projectsAsync.when(
                data: (projects) {
                  final isOfflineData = ref.read(projectsProvider.notifier).isOffline;
                  
                  Widget content;
                  if (projects.isEmpty) {
                    content = const Center(child: Text('No projects found.'));
                  } else {
                    content = ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return ListTile(
                          title: Text(project.name),
                          subtitle: Text(project.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${project.taskCount} tasks'),
                              if (user.role == 'org_admin') ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditProjectDialog(context, ref, project);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDeleteProject(context, ref, project.id);
                                  },
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            context.push('/project/${project.id}');
                          },
                        );
                      },
                    );
                  }

                  if (isOfflineData) {
                    return Column(
                      children: [
                        Container(
                          color: Colors.orange,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          child: const Text('⚠️ Offline Mode - Displaying cached data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                        Expanded(child: content),
                      ],
                    );
                  }
                  
                  return content;
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Error: $err', textAlign: TextAlign.center),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(projectsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: userAsync.value?.role == 'org_admin'
          ? FloatingActionButton(
              onPressed: () {
                _showCreateProjectDialog(context, ref, userAsync.value!.orgId);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref, String orgId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newProject = Project(
                  id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
                  orgId: orgId,
                  name: titleController.text,
                  description: descController.text,
                  taskCount: 0,
                  status: 'active',
                  createdAt: DateTime.now(),
                );
                await ref.read(projectsProvider.notifier).createProject(newProject);
                if (context.mounted) {
                  final error = ref.read(projectsProvider).error;
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
  }

  void _showEditProjectDialog(BuildContext context, WidgetRef ref, Project project) {
    final titleController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedProject = project.copyWith(
                  name: titleController.text,
                  description: descController.text,
                );
                await ref.read(projectsProvider.notifier).updateProject(updatedProject);
                if (context.mounted) {
                  final error = ref.read(projectsProvider).error;
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
  }

  void _confirmDeleteProject(BuildContext context, WidgetRef ref, String projectId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(projectsProvider.notifier).deleteProject(projectId);
                if (context.mounted) {
                  final error = ref.read(projectsProvider).error;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Consumer(
              builder: (context, ref, child) {
                final notifsAsync = ref.watch(notificationsProvider(userId));
                return notifsAsync.when(
                  data: (notifs) {
                    if (notifs.isEmpty) return const Center(child: Text('No notifications'));
                    return ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (context, index) {
                        final notif = notifs[index];
                        final title = notif.type == 'task_assigned' ? 'Task Assigned' : notif.type;
                        return ListTile(
                          title: Text(title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                          subtitle: Text(notif.message),
                          trailing: notif.isRead ? null : IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              await ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                              ref.invalidate(notificationsProvider(userId));
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/task/${notif.taskId}');
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }
}
