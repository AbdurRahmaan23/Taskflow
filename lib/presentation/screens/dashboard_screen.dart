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
          Row(
            children: [
              const Text('Offline:'),
              Consumer(
                builder: (context, ref, child) {
                  final isOffline = ref.watch(debugOfflineProvider);
                  return Switch(
                    value: isOffline,
                    onChanged: (val) {
                      ref.read(mockDataSourceProvider).simulateOffline = val;
                      ref.read(debugOfflineProvider.notifier).state = val;
                    },
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                _showNotificationsDialog(context, ref, user.id);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
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
                if (projects.isEmpty) {
                  return const Center(child: Text('No projects found.'));
                }
                return ListView.builder(
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
                          if (user.role == 'org_admin')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDeleteProject(context, ref, project.id);
                              },
                            ),
                        ],
                      ),
                      onTap: () {
                        context.push('/project/${project.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) {
                if (projectsAsync.hasValue && projectsAsync.value!.isNotEmpty) {
                  // Preserve data and show banner
                  return Column(
                    children: [
                      Container(color: Colors.red, width: double.infinity, padding: const EdgeInsets.all(8), child: const Text('Offline Mode - Showing cached data', style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: projectsAsync.value!.length,
                          itemBuilder: (context, index) {
                            final project = projectsAsync.value![index];
                            return ListTile(
                              title: Text(project.name),
                              subtitle: Text(project.description),
                              trailing: Text('${project.taskCount} tasks'),
                              onTap: () => context.push('/project/${project.id}'),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Offline or Error: $err', textAlign: TextAlign.center),
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
                await ref.read(projectRepositoryProvider).createProject(newProject);
                ref.invalidate(projectsProvider);
                if (context.mounted) Navigator.pop(context);
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
                await ref.read(projectRepositoryProvider).deleteProject(projectId);
                ref.invalidate(projectsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                        return ListTile(
                          title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                          subtitle: Text(notif.message),
                          trailing: notif.isRead ? null : IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              await ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                              ref.invalidate(notificationsProvider(userId));
                            },
                          ),
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
