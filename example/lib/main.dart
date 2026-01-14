import 'package:flutter/material.dart';
import 'package:offline_sync/offline_sync.dart';

import 'dart:async';

void main() {
  OfflineSync.onSyncStart = () {
    debugPrint("🔄 CALLBACK: Sync started");
  };

  OfflineSync.onRequestSuccess = (id) {
    debugPrint("✅ CALLBACK: Request synced → $id");
  };

  OfflineSync.onRequestFailure = (id, retry) {
    debugPrint("❌ CALLBACK: Request failed (retry $retry) → $id");
  };

  OfflineSync.onRequestsDiscarded = (count) {
    debugPrint("🗑️ CALLBACK: Discarded $count failed requests");
  };

  OfflineSync.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage());
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
      appBar: AppBar(title: const Text("Offline Sync – SQLite Proof")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Pending requests in SQLite: $_pending",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                await OfflineSync.post(
                  url: "https://jsonplaceholder.typicode.com/posts",

                  body: {
                    "title": "Offline Test",
                    "body": "Stored in SQLite",
                    "userId": 1,
                  },
                );
                await _refreshCount();
              },
              child: const Text("Send Request"),
            ),

            ElevatedButton(
              onPressed: () async {
                await OfflineSync.clearAll();
                await _refreshCount();
              },
              child: const Text("Clear Pending Requests"),
            ),

            ElevatedButton(
              onPressed: () async {
                final removed = await OfflineSync.clearFailedOnly();
                debugPrint("Removed via API: $removed");
                await _refreshCount();
              },
              child: const Text("Clear Failed Requests"),
            ),
          ],
        ),
      ),
    );
  }
}
