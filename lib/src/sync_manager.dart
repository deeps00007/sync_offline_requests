import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'local_db.dart';
import 'request_model.dart';

/// Responsible for:
/// - Detecting internet availability
/// - Sending queued offline requests
/// - Retrying failed requests safely
class SyncManager {
  /// Called when a sync cycle starts
  VoidCallback? onSyncStart;

  /// Called when a request is synced successfully
  void Function(String requestId)? onRequestSuccess;

  /// Called when a request fails to sync
  void Function(String requestId, int retryCount)? onRequestFailure;

  /// Maximum retry attempts per request
  static const int maxRetryCount = 3;

  final StreamController<void> _syncController =
      StreamController<void>.broadcast();

  /// Stream that emits when a sync cycle finishes
  Stream<void> get onSyncComplete => _syncController.stream;

  bool _isListening = false;

  /// Starts listening to connectivity changes
  /// and triggers sync when internet is restored
  void startAutoSyncListener() {
    if (_isListening) return;
    _isListening = true;

    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncPendingRequests();
      }
    });
  }

  /// Sync all pending requests safely
  Future<void> syncPendingRequests() async {
    final hasInternet = await _hasInternet();
    if (!hasInternet) return;

    onSyncStart?.call();

    final requests = await LocalDatabase.instance.getPendingRequests();

    for (final request in requests) {
      if (request.retryCount >= maxRetryCount) continue;

      final success = await _sendRequest(request);

      if (success) {
        await LocalDatabase.instance.deleteRequest(request.id);
        onRequestSuccess?.call(request.id);
      } else {
        final newRetryCount = request.retryCount + 1;

        await LocalDatabase.instance.insertRequest(
          OfflineRequest(
            id: request.id,
            url: request.url,
            method: request.method,
            body: request.body,
            retryCount: newRetryCount,
            createdAt: request.createdAt,
          ),
        );

        onRequestFailure?.call(request.id, newRetryCount);
      }
    }

    _syncController.add(null);
  }

  /// Send a single request to server
  Future<bool> _sendRequest(OfflineRequest request) async {
    try {
      final uri = Uri.parse(request.url);
      late http.Response response;

      switch (request.method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            body: request.body,
            headers: {'Content-Type': 'application/json'},
          );
          break;

        case 'PUT':
          response = await http.put(
            uri,
            body: request.body,
            headers: {'Content-Type': 'application/json'},
          );
          break;

        case 'DELETE':
          response = await http.delete(uri);
          break;

        default:
          return false;
      }

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Check if device has network connection
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
