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

  Future<void> _refreshCount() async {
    final count = await OfflineSync.pendingCount();
    setState(() {
      _pending = count;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pending requests in SQLite: $_pending',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            // POST request with Authorization header
            ElevatedButton(
              onPressed: () async {
                await OfflineSync.post(
                  url: 'https://jsonplaceholder.typicode.com/posts',
                  body: {
                    'title': 'Offline POST',
                    'body': 'Stored in SQLite',
                    'userId': 1,
                  },
                  headers: {'Authorization': 'Bearer demo_token'},
                );
                await _refreshCount();
              },
              child: const Text('POST Request'),
            ),

            // PUT request
            ElevatedButton(
              onPressed: () async {
                await OfflineSync.put(
                  url: 'https://jsonplaceholder.typicode.com/posts/1',
                  body: {
                    'title': 'Updated Title',
                    'body': 'Updated body',
                    'userId': 1,
                  },
                  headers: {'Authorization': 'Bearer demo_token'},
                );
                await _refreshCount();
              },
              child: const Text('PUT Request'),
            ),

            // DELETE request
            ElevatedButton(
              onPressed: () async {
                await OfflineSync.delete(
                  url: 'https://jsonplaceholder.typicode.com/posts/1',
                  headers: {'Authorization': 'Bearer demo_token'},
                );
                await _refreshCount();
              },
              child: const Text('DELETE Request'),
            ),
            
            const SizedBox(height: 20),

            // GET request with caching
            ElevatedButton(
              onPressed: () async {
                final response = await OfflineSync.get(
                  url: 'https://jsonplaceholder.typicode.com/posts/1',
                );
                debugPrint('GET Response: $response');
              },
              child: const Text('GET Request (Cached)'),
            ),

            // MULTIPART request
            ElevatedButton(
              onPressed: () async {
                await OfflineSync.multipart(
                  url: 'https://jsonplaceholder.typicode.com/posts',
                  files: {'dummy_file': '/path/to/dummy.jpg'},
                );
                await _refreshCount();
              },
              child: const Text('Multipart Upload'),
            ),

            const Divider(height: 40),

            ElevatedButton(
              onPressed: () async {
                await OfflineSync.syncNow();
                await _refreshCount();
              },
              child: const Text('Manual Sync'),
            ),

            ElevatedButton(
              onPressed: () async {
                await OfflineSync.clearAll();
                await _refreshCount();
              },
              child: const Text('Clear All Requests'),
            ),

            ElevatedButton(
              onPressed: () async {
                final removed = await OfflineSync.clearFailedOnly();
                debugPrint('Removed $removed failed requests');
                await _refreshCount();
              },
              child: const Text('Clear Failed Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
