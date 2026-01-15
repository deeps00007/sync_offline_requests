# sync_offline_requests

[![Pub Version](https://img.shields.io/pub/v/sync_offline_requests.svg)](https://pub.dev/packages/sync_offline_requests)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)

**Offline-first HTTP request handling for Flutter applications.**

`sync_offline_requests` ensures your app remains functional even in unreliable network conditions. It automatically queues failed API requests when the device is offline and synchronizes them effectively once internet connectivity is restored, using a persistent SQLite-backed queue.

---

## ✨ Features

- **📡 Offline-First Architecture**: Seamlessly handle HTTP requests regardless of network status.
- **🧾 Persistent Queue**: Requests are safely stored in a local SQLite database, surviving app restarts.
- **🔁 Intelligent Retry**: Configurable retry mechanisms with maximum retry limits for failed sync attempts.
- **🌐 Auto-Synchronization**: Automatically detects network restoration and processes the queue.
- **⏳ FIFO Processing**: Maintains the order of operations with First-In-First-Out processing.
- **🧠 Minimal API**: Simple to integrate with existing projects.

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  sync_offline_requests: ^1.0.3
```

Run the fetch command:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Initialize

Initialize the package in your `main()` function. This sets up the database and network listeners.

```dart
import 'package:flutter/material.dart';
import 'package:sync_offline_requests/sync_offline_requests.dart';

void main() {
  OfflineSync.initialize();
  runApp(const MyApp());
}
```

### 2. Send Requests

Use `OfflineSync` to send your HTTP requests. The package handles the rest.

```dart
try {
  await OfflineSync.post(
    url: 'https://example.com/api/data',
    body: {
      'name': 'John Doe',
      'role': 'Developer',
    },
  );
  print('Request processed (either sent or queued)');
} catch (e) {
  print('Error processing request: $e');
}
```

**Behavior:**
- **Online**: The request is sent immediately.
- **Offline**: The request is saved to the local database and queued for later synchronization.

---

## 🧠 Core Concepts

1.  **Storage**: All requests are initially passed to the `OfflineSync` handler.
2.  **Queue**: If offline, the request is stored in SQLite.
3.  **Monitoring**: The package listens for connectivity changes (Wi-Fi, Mobile Data).
4.  **Sync**: When a connection is re-established, the queue is processed.
5.  **Retry Logic**: Failed sync attempts are retried up to a configurable limit before being discarded to prevent infinite loops.

---

## � Advanced Usage

### Manual Sync

You can Force a sync operation manually, for example, on a "Pull to Refresh" action.

```dart
await OfflineSync.syncNow();
```

### Check Pending Requests

Get the current count of requests waiting in the queue.

```dart
final int pendingCount = await OfflineSync.pendingCount();
print('Pending requests: $pendingCount');
```

---

## ⚠️ Limitations

- Currently supports **POST**, **PUT**, and **DELETE** methods.
- Designed primarily for **JSON** payloads.
- Not optimized for large multi-part file uploads.
- Background sync (when the app is closed) is platform-dependent and currently relies on the app being in the foreground or suspended state.

---

## �️ Roadmap

- [ ] GET request caching support
- [ ] Custom headers configuration
- [ ] Enhanced background sync work manager
- [ ] Conflict resolution strategies
- [ ] Payload encryption

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## � License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
