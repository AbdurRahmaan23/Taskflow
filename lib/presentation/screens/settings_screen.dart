import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final isDark = ref.watch(themeModeProvider);
    final isOffline = ref.watch(debugOfflineProvider);
    final isError = ref.watch(debugErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.email),
                subtitle: Text('Role: ${user.role}'),
                isThreeLine: false,
              ),
              const Divider(height: 32),
              
              const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode),
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              ),
              const Divider(height: 32),
              
              const Text('Developer & Debug (Mock)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Simulate Offline Mode'),
                subtitle: const Text('Forces network to fail and use local cache'),
                secondary: const Icon(Icons.wifi_off),
                value: isOffline,
                onChanged: (val) {
                  ref.read(mockDataSourceProvider).simulateOffline = val;
                  ref.read(debugOfflineProvider.notifier).state = val;
                },
              ),
              SwitchListTile(
                title: const Text('Simulate API Error'),
                subtitle: const Text('Forces a random 500 API error'),
                secondary: const Icon(Icons.error_outline),
                value: isError,
                onChanged: (val) {
                  ref.read(mockDataSourceProvider).simulateError = val;
                  ref.read(debugErrorProvider.notifier).state = val;
                },
              ),
              const Divider(height: 32),

              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
