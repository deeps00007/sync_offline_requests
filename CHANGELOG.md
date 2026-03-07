## 1.2.0

### New Features
- Added `OfflineSync.put()` for offline-first PUT requests
- Added `OfflineSync.delete()` for offline-first DELETE requests
- Added `headers` parameter to `post()`, `put()`, and `delete()` for custom HTTP headers (e.g. Authorization tokens)
- `maxRetryCount` is now configurable via `OfflineSync.initialize(maxRetryCount: 5)`

### Bug Fixes
- Fixed compatibility with `connectivity_plus` v6.x which returns `List<ConnectivityResult>` instead of a single value
  
### Improvements
- Bumped `connectivity_plus` dependency to `^6.0.0`
- SQLite database migrated to version 2 (adds `headers` column with backward-compatible migration)
- Added unit tests for initialization, callbacks, and queue management

## 1.1.1
- Removed decorative icons from documentation for cleaner look
- Minor documentation updates

## 1.1.0
- Bumped version to stable 1.1.0
- Stabilized API and improved documentation

## 1.0.5
- Improved documentation with failed request cleanup features
- Added usage examples for clearing failed requests

## 1.0.4
- Fixed README.md formatting and emoji encoding
- Improved code examples in documentation

## 1.0.3
- Improved documentation and package metadata

## 1.0.0

- Initial stable release
- Offline-first HTTP request queue
- Automatic sync when internet is restored
- Retry mechanism with configurable max retries
- SQLite-based persistent request storage
- Sync lifecycle callbacks
- Example application included
