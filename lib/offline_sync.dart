import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'src/request_model.dart';
import 'src/local_db.dart';
import 'src/sync_manager.dart';

/// Called when a sync cycle starts
typedef SyncStartCallback = void Function();

/// Called when a request is synced successfully
typedef SyncSuccessCallback = void Function(String requestId);

/// Called when a request fails to sync
typedef SyncFailureCallback = void Function(String requestId, int retryCount);

/// Public API for the Offline Sync package.
///
/// App developers only interact with this class.
/// All internal logic is hidden.
class OfflineSync {
  static final _uuid = Uuid();
  static final _syncManager = SyncManager();

  static bool _initialized = false;

  // Optional callbacks for app developers
  static SyncStartCallback? onSyncStart;
  static SyncSuccessCallback? onRequestSuccess;
  static SyncFailureCallback? onRequestFailure;

  /// Initialize the package.
  ///
  /// Safe to call multiple times.
  /// Automatically handles Flutter bindings.
  static void initialize() {
    if (_initialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    // 🔌 wire callbacks
    _syncManager.onSyncStart = () {
      onSyncStart?.call();
    };

    _syncManager.onRequestSuccess = (id) {
      onRequestSuccess?.call(id);
    };

    _syncManager.onRequestFailure = (id, retryCount) {
      onRequestFailure?.call(id, retryCount);
    };

    _syncManager.startAutoSyncListener();
    _initialized = true;
  }

  /// Stream triggered after a sync cycle completes
  static Stream<void> get onSyncComplete => _syncManager.onSyncComplete;

  /// Send a POST request using offline-first strategy
  static Future<void> post({
    required String url,
    required Map<String, dynamic> body,
  }) async {
    final request = OfflineRequest(
      id: _uuid.v4(),
      url: url,
      method: 'POST',
      body: jsonEncode(body),
      retryCount: 0,
      createdAt: DateTime.now(),
    );

    await LocalDatabase.instance.insertRequest(request);
    await _syncManager.syncPendingRequests();
  }

  /// Manually trigger sync (optional)
  static Future<void> syncNow() async {
    await _syncManager.syncPendingRequests();
  }

  /// Get number of pending offline requests
  static Future<int> pendingCount() async {
    return LocalDatabase.instance.getPendingCount();
  }

  /// Clear all pending offline requests
  /// Useful for logout, reset, or manual cleanup
  static Future<void> clearAll() async {
    await LocalDatabase.instance.clearAllRequests();
  }

  /// Clear only failed requests (retry limit exceeded)
  ///
  /// Returns number of removed requests
  static Future<int> clearFailedOnly() async {
    return await LocalDatabase.instance.clearFailedRequests(
      SyncManager.maxRetryCount,
    );
  }

  /// Called when failed requests are discarded
  static void Function(int count)? onRequestsDiscarded;
}
