import 'package:flutter/material.dart';
import 'package:sync_offline_requests/sync_offline_requests.dart';

void main() {
  // Set optional callbacks before initializing
  OfflineSync.onSyncStart = () {
    debugPrint('🔄 CALLBACK: Sync started');
  };

  OfflineSync.onRequestSuccess = (id) {
    debugPrint('✅ CALLBACK: Request synced → $id');
  };

  OfflineSync.onRequestFailure = (id, retry) {
    debugPrint('❌ CALLBACK: Request failed (retry $retry) → $id');
  };

  OfflineSync.onRequestsDiscarded = (count) {
    debugPrint('🗑️ CALLBACK: Discarded $count failed requests');
  };

  // Initialize with custom retry limit (default: 3)
  OfflineSync.initialize(maxRetryCount: 5);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sync_offline_requests Demo',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pending = 0;
  Map<RequestPriority, int> _priorityCounts = {};

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final count = await OfflineSync.pendingCount();
    final priorityCounts = await OfflineSync.getPriorityCounts();
    setState(() {
      _pending = count;
      _priorityCounts = priorityCounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync Demo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Total pending requests
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Total Pending: $_pending',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      // Priority breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPriorityChip(
                            'High Priority',
                            _priorityCounts[RequestPriority.high] ?? 0,
                            Colors.red,
                          ),
                          _buildPriorityChip(
                            'Medium Priority',
                            _priorityCounts[RequestPriority.medium] ?? 0,
                            Colors.orange,
                          ),
                          _buildPriorityChip(
                            'Low Priority',
                            _priorityCounts[RequestPriority.low] ?? 0,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // High Priority Section
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔥 HIGH PRIORITY (Syncs First)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await OfflineSync.post(
                            url: 'https://jsonplaceholder.typicode.com/posts',
                            body: {
                              'title': 'URGENT: Payment Confirmation',
                              'body': 'High priority request',
                              'userId': 1,
                              'priority': 'high',
                            },
                            headers: {'Authorization': 'Bearer demo_token'},
                            priority: RequestPriority.high,
                          );
                          await _refreshCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔥 High priority request queued!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        icon: const Icon(Icons.priority_high),
                        label: const Text('Send HIGH Priority POST'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Medium Priority Section (Default)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⭐ MEDIUM PRIORITY (Default)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () async {
                          await OfflineSync.post(
                            url: 'https://jsonplaceholder.typicode.com/posts',
                            body: {
                              'title': 'Normal User Data',
                              'body': 'Medium priority request',
                              'userId': 1,
                            },
                            headers: {'Authorization': 'Bearer demo_token'},
                            // priority defaults to medium
                          );
                          await _refreshCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⭐ Medium priority request queued!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Send MEDIUM Priority POST'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () async {
                          await OfflineSync.put(
                            url: 'https://jsonplaceholder.typicode.com/posts/1',
                            body: {
                              'title': 'Updated User Data',
                              'body': 'Medium priority update',
                              'userId': 1,
                            },
                            headers: {'Authorization': 'Bearer demo_token'},
                            priority: RequestPriority.medium,
                          );
                          await _refreshCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⭐ Medium priority PUT request queued!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Send MEDIUM Priority PUT'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Low Priority Section
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💤 LOW PRIORITY (Syncs Last)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          await OfflineSync.post(
                            url: 'https://jsonplaceholder.typicode.com/posts',
                            body: {
                              'title': 'Analytics Event',
                              'body': 'Page view tracking',
                              'userId': 1,
                            },
                            headers: {'Authorization': 'Bearer demo_token'},
                            priority: RequestPriority.low,
                          );
                          await _refreshCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('💤 Low priority request queued!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics),
                        label: const Text('Send LOW Priority POST'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          await OfflineSync.delete(
                            url: 'https://jsonplaceholder.typicode.com/posts/1',
                            headers: {'Authorization': 'Bearer demo_token'},
                            priority: RequestPriority.low,
                          );
                          await _refreshCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('💤 Low priority DELETE request queued!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Send LOW Priority DELETE'),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 40),

              // Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await OfflineSync.syncNow();
                      await _refreshCount();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Manual sync triggered!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Manual Sync'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await OfflineSync.clearAll();
                      await _refreshCount();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ All requests cleared!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final removed = await OfflineSync.clearFailedOnly();
                      await _refreshCount();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed $removed failed requests'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear Failed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 How Priority Works:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• HIGH priority requests sync FIRST\n'
                            '• MEDIUM priority requests sync SECOND\n'
                            '• LOW priority requests sync LAST\n'
                            '• When offline, all requests are queued with their priority\n'
                            '• When internet returns, requests sync in priority order',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.amber.shade100,
                        child: const Text(
                          '💡 TIP: Turn off WiFi/Data, send high priority requests, '
                              'then turn on internet to see them sync first!',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}