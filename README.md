# sync_offline_requests

[![Pub Version](https://img.shields.io/pub/v/sync_offline_requests.svg)](https://pub.dev/packages/sync_offline_requests)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)

**Offline-first HTTP request handling for Flutter applications.**

`sync_offline_requests` ensures your app remains functional even in unreliable network conditions. It automatically queues failed API requests when the device is offline and synchronizes them effectively once internet connectivity is restored, using a persistent SQLite-backed queue.

---

## What's New in v1.3.0

- **GET request caching** — Offline-capable `GET` requests that auto-fallback to local SQLite cache.
- **Multipart support** — Easily queue file uploads (images, docs) offline. Local file paths are securely stored and uploaded automatically when online.
- **Custom Headers** — Pass `Authorization`, `X-Api-Key`, or any header per request.

## What's New in v1.2.0
- **Custom Headers** — Pass `Authorization`, `X-Api-Key`, or any header per request.
- **Configurable retry limit** — Set `maxRetryCount` in `initialize()` instead of being stuck at 3.
- **Bug fix** — Compatibility with `connectivity_plus` v6.x (returns `List<ConnectivityResult>`).
- **DB Migration** — Existing users upgrade seamlessly; no data loss.
- **Unit tests** added for initialization and callbacks.

---

## Features

- **Offline-First Architecture**: Seamlessly handle HTTP requests regardless of network status.
- **Persistent Queue**: Requests are safely stored in a local SQLite database, surviving app restarts.
- **Automatic cleanup** of failed requests after retry limit is exceeded
- **Intelligent Retry**: Configurable retry mechanisms with configurable maximum retry limits.
- **Auto-Synchronization**: Automatically detects network restoration and processes the queue.
- **FIFO Processing**: Maintains the order of operations with First-In-First-Out processing.
- **Minimal API**: Simple to integrate with existing projects.
- **Custom Headers**: Pass Authorization tokens or any HTTP header per request.
- **GET Caching**: Smart offline caching for GET responses.
- **Multipart Uploads**: Offline queuing for bulky image/document uploads.
- **Full REST support**: Offline-first support for POST, PUT, DELETE, GET, and Multipart.

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  sync_offline_requests: ^1.3.0
```

Run the fetch command:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize

Initialize in your `main()` function before `runApp`. Set optional callbacks and a custom retry limit.

```dart
import 'package:flutter/material.dart';
import 'package:sync_offline_requests/sync_offline_requests.dart';

void main() {
  // Optional: listen to sync events
  OfflineSync.onSyncStart = () => print('Sync started');
  OfflineSync.onRequestSuccess = (id) => print('Synced: $id');
  OfflineSync.onRequestFailure = (id, retry) => print('Failed: $id (retry $retry)');

  // Initialize — maxRetryCount is optional, default is 3
  OfflineSync.initialize(maxRetryCount: 5);

  runApp(const MyApp());
}
```

### 2. GET Request (with Offline Caching)

```dart
// Online: fetches from API & saves to SQLite
// Offline: returns the locally cached JSON!
final response = await OfflineSync.get(
  url: 'https://example.com/api/data',
  headers: {'Authorization': 'Bearer your_token'},
);

if (response != null) {
  print(response['name']);
}
```

### 3. POST Request

```dart
await OfflineSync.post(
  url: 'https://example.com/api/data',
  body: {'name': 'John', 'role': 'Developer'},
  headers: {'Authorization': 'Bearer your_token'}, // optional
);
```

### 3. PUT Request

```dart
await OfflineSync.put(
  url: 'https://example.com/api/user/1',
  body: {'name': 'Updated Name'},
  headers: {'Authorization': 'Bearer your_token'}, // optional
);
```

### 5. DELETE Request

```dart
await OfflineSync.delete(
  url: 'https://example.com/api/user/1',
  headers: {'Authorization': 'Bearer your_token'}, // optional
);
```

### 6. Multipart File Uploads (Images/Docs)

Instead of saving heavy images to JSON or memory, we store the **local file path** directly to SQLite. When the user connects to WiFi, the file automatically gets sent via `http.MultipartRequest`!

```dart
await OfflineSync.multipart(
  url: 'https://example.com/upload',
  method: 'POST', // or 'PUT'
  body: {'userId': '123'}, 
  files: {
    'profile_picture': '/data/user/0/com.app/cache/image123.jpg',
  },
);
```

**Behavior for all methods:**
- **Online**: The request is sent immediately.
- **Offline**: The request is saved to SQLite and auto-synced when internet returns.

---

## Core Concepts

1.  **Storage**: All requests are initially passed to the `OfflineSync` handler.
2.  **Queue**: If offline, the request is stored in SQLite.
3.  **Monitoring**: The package listens for connectivity changes (Wi-Fi, Mobile Data).
4.  **Sync**: When a connection is re-established, the queue is processed.
5.  **Retry Logic**: Failed sync attempts are retried up to a configurable limit before being discarded to prevent infinite loops.

### Retry & Cleanup Strategy

- Each request has a retry counter
- Failed sync attempts increment the retry count
- Once the retry limit is exceeded:
  - The request is marked as failed
  - It can be safely removed using `clearFailedOnly()`
  - This prevents infinite retry loops and battery drain

---

## Advanced Usage

### Manual Sync

You can force a sync operation manually, for example, on a "Pull to Refresh" action.

```dart
await OfflineSync.syncNow();
```

### PUT Request

Update data on your API, stored and retried offline if needed.

```dart
await OfflineSync.put(
  url: 'https://example.com/api/user/1',
  body: {'name': 'Updated Name'},
  headers: {'Authorization': 'Bearer your_token'},
);
```

### DELETE Request

```dart
await OfflineSync.delete(
  url: 'https://example.com/api/user/1',
  headers: {'Authorization': 'Bearer your_token'},
);
```

### Custom Headers

Pass any HTTP headers (e.g. auth tokens, API keys) with your requests:

```dart
await OfflineSync.post(
  url: 'https://example.com/api/data',
  body: {'title': 'Hello'},
  headers: {
    'Authorization': 'Bearer your_token_here',
    'X-App-Version': '1.0.0',
  },
);

### Check Pending Requests

Get the current count of requests waiting in the queue.

```dart
final int pendingCount = await OfflineSync.pendingCount();
print('Pending requests: $pendingCount');
```

## Failed Request Cleanup

To prevent infinite retries and database growth, requests that exceed the
maximum retry limit are considered **failed**.

You can manually remove such requests using:

```dart
final removedCount = await OfflineSync.clearFailedOnly();
print('Removed $removedCount failed requests');
```

This helps keep local storage clean and avoids unnecessary sync attempts.

---

## Limitations

- Currently supports **POST**, **PUT**, and **DELETE** methods.
- Minimal file upload mapping support (one file per key path). 
- Background sync (when the app is completely closed) is platform-dependent and currently relies on the app being in the foreground or suspended state.

---

## Roadmap

- [x] GET request caching support
- [x] Multi-part offline mapping
- [ ] Enhanced background sync work manager
- [ ] Conflict resolution strategies
- [ ] Payload encryption

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
