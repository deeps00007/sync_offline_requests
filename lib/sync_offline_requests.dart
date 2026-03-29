import 'dart:convert';
export 'src/app_enum.dart' show RequestPriority;
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'src/request_model.dart';
import 'src/local_db.dart';
import 'src/sync_manager.dart';
import 'sync_offline_requests.dart' show RequestPriority;

/// Called when a sync cycle starts
typedef SyncStartCallback = void Function();

/// Called when a request is synced successfully
typedef SyncSuccessCallback = void Function(String requestId);

/// Called when a request fails to sync
typedef SyncFailureCallback = void Function(String requestId, int retryCount);

/// Public API for the sync_offline_requests package.
///
/// App developers only interact with this class.
/// All internal logic is hidden.
class OfflineSync {
  static final _uuid = Uuid();
  static late SyncManager _syncManager;

  static bool _initialized = false;

  // Optional callbacks for app developers
  static SyncStartCallback? onSyncStart;
  static SyncSuccessCallback? onRequestSuccess;
  static SyncFailureCallback? onRequestFailure;

  /// Called when failed requests are discarded
  static void Function(int count)? onRequestsDiscarded;

  /// Initialize the package.
  ///
  /// Safe to call multiple times.
  /// Automatically handles Flutter bindings.
  ///
  /// [maxRetryCount] — how many times a failed request is retried
  /// before being considered permanently failed. Default is 3.
  static void initialize({int maxRetryCount = 3}) {
    if (_initialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    _syncManager = SyncManager(maxRetryCount: maxRetryCount);

    // Wire callbacks
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

  // ─────────────────────────────────────────
  // HTTP Methods
  // ─────────────────────────────────────────

  /// Send a POST request using offline-first strategy.
  ///
  /// [url] — the API endpoint
  /// [body] — the JSON request body
  /// [headers] — optional HTTP headers (e.g. Authorization)
  static Future<void> post({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium, // NEW: priority parameter
  }) async {
    await _enqueue(url: url, method: 'POST', body: body, headers: headers, priority: priority);
  }

  /// Send a PUT request using offline-first strategy.
  ///
  /// [url] — the API endpoint
  /// [body] — the JSON request body
  /// [headers] — optional HTTP headers (e.g. Authorization)
  static Future<void> put({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium, // NEW: priority parameter
  }) async {
    await _enqueue(url: url, method: 'PUT', body: body, headers: headers, priority: priority);
  }

  /// Send a DELETE request using offline-first strategy.
  ///
  /// [url] — the API endpoint
  /// [headers] — optional HTTP headers (e.g. Authorization)
  static Future<void> delete({
    required String url,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium, // NEW: priority parameter
  }) async {
    await _enqueue(url: url, method: 'DELETE', body: {}, headers: headers, priority: priority);
  }

  // ─────────────────────────────────────────
  // Queue Management
  // ─────────────────────────────────────────

  /// Manually trigger sync (optional)
  static Future<void> syncNow() async {
    await _syncManager.syncPendingRequests();
  }

  /// Get number of pending offline requests
  static Future<int> pendingCount() async {
    return LocalDatabase.instance.getPendingCount();
  }

  /// Get count of pending requests by priority
  static Future<Map<RequestPriority, int>> getPriorityCounts() async {
    return LocalDatabase.instance.getPriorityCounts();
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
    return LocalDatabase.instance.clearFailedRequests(
      _syncManager.maxRetryCount,
    );
  }

  // ─────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────

  static Future<void> _enqueue({
    required String url,
    required String method,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
  }) async {
    assert(_initialized, 'OfflineSync.initialize() must be called first.');

    final request = OfflineRequest(
      id: _uuid.v4(),
      url: url,
      method: method,
      body: jsonEncode(body),
      headers: headers,
      retryCount: 0,
      createdAt: DateTime.now(),
      priority: priority, // NEW: set priority
    );

    await LocalDatabase.instance.insertRequest(request);
    await _syncManager.syncPendingRequests();
  }
}
