import 'package:flutter_test/flutter_test.dart';
import 'package:sync_offline_requests/sync_offline_requests.dart';

void main() {
  // Ensure Flutter bindings are initialized before all tests
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('OfflineSync initialization', () {
    test('initialize() can be called multiple times safely', () {
      // Should not throw even when called multiple times
      OfflineSync.initialize();
      OfflineSync.initialize();
    });

    test('initialize() accepts a custom maxRetryCount', () {
      // No assertion needed — just verifying it does not throw
      OfflineSync.initialize(maxRetryCount: 5);
    });
  });

  group('OfflineSync callbacks', () {
    test('onSyncStart callback can be set and cleared', () {
      bool called = false;
      OfflineSync.onSyncStart = () => called = true;
      expect(called, isFalse); // Callback should not auto-fire on assignment
      OfflineSync.onSyncStart = null; // cleanup
    });

    test('onRequestSuccess callback can be set and cleared', () {
      OfflineSync.onRequestSuccess = (id) {};
      OfflineSync.onRequestSuccess = null; // cleanup
    });

    test('onRequestFailure callback can be set and cleared', () {
      OfflineSync.onRequestFailure = (id, retryCount) {};
      OfflineSync.onRequestFailure = null; // cleanup
    });

    test('onRequestsDiscarded callback can be set and cleared', () {
      OfflineSync.onRequestsDiscarded = (count) {};
      OfflineSync.onRequestsDiscarded = null; // cleanup
    });
  });
}
