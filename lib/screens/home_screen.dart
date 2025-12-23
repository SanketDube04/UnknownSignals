import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'scan_screen.dart';
import 'create_remote_screen.dart';
import 'remote_play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Remote'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection Status
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                // Note: We'll add bluetooth status listener in AppProvider if needed directly
                // For now relying on checking bluetooth service state
                // But let's keep it simple: Access BluetoothService singleton or via Provider
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth),
                      const SizedBox(width: 8),
                      const Text("Status: "),
                      // This is a placeholder, we might want to expose connection state stream
                      // through AppProvider to make it reactive
                      const Text("Ready"),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ScanScreen()),
                          );
                        },
                        child: const Text("Connect"),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Create New Remote Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateRemoteScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Create New Remote"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Remotes",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Remotes List
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.remotes.isEmpty) {
                    return const Center(child: Text("No remotes created yet."));
                  }
                  return ListView.builder(
                    itemCount: provider.remotes.length,
                    itemBuilder: (context, index) {
                      final remote = provider.remotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(remote.name[0].toUpperCase()),
                          ),
                          title: Text(remote.name),
                          subtitle: Text(
                              "Created: ${remote.createdAt.split('T')[0]}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              provider.deleteRemote(remote.id!);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RemotePlayScreen(remote: remote),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
