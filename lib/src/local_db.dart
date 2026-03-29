import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'app_enum.dart';
import 'request_model.dart';

/// Handles all local database operations
/// related to offline API requests.
///
/// This class is intentionally isolated
/// from networking and UI logic.
class LocalDatabase {
  /// Singleton instance
  static final LocalDatabase instance = LocalDatabase._internal();

  LocalDatabase._internal();

  static Database? _database;

  /// Lazily initialize and return database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize SQLite database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_sync.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create required tables on first launch
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_requests (
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        method TEXT NOT NULL,
        body TEXT NOT NULL,
        headers TEXT NOT NULL DEFAULT '{}',
        retryCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  /// Handle DB schema migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add headers column
      await db.execute(
        "ALTER TABLE offline_requests ADD COLUMN headers TEXT NOT NULL DEFAULT '{}'",
      );
    }
    if (oldVersion < 3) {
      // Add priority column with default medium (1)
      await db.execute(
        "ALTER TABLE offline_requests ADD COLUMN priority INTEGER NOT NULL DEFAULT 1",
      );
    }
  }

  /// Insert or update an offline request
  Future<void> insertRequest(OfflineRequest request) async {
    final db = await database;

    await db.insert(
      'offline_requests',
      request.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all pending requests in FIFO order
  Future<List<OfflineRequest>> getPendingRequests() async {
    final db = await database;

    final records = await db.query(
      'offline_requests',
      orderBy: 'priority ASC, createdAt ASC', // priority 0 (high) comes first
    );

    return records.map((map) => OfflineRequest.fromMap(map)).toList();
  }

  /// Delete request after successful sync
  Future<void> deleteRequest(String id) async {
    final db = await database;
    await db.delete('offline_requests', where: 'id = ?', whereArgs: [id]);
  }

  /// Return number of pending offline requests
  Future<int> getPendingCount() async {
    final db = await database;

    final result = await db.rawQuery('SELECT COUNT(*) FROM offline_requests');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete ALL pending offline requests
  Future<void> clearAllRequests() async {
    final db = await database;
    await db.delete('offline_requests');
  }

  /// Delete requests that exceeded max retry limit
  Future<int> clearFailedRequests(int maxRetryCount) async {
    final db = await database;

    return await db.delete(
      'offline_requests',
      where: 'retryCount >= ?',
      whereArgs: [maxRetryCount],
    );
  }
  /// Get count of requests by priority
  Future<Map<RequestPriority, int>> getPriorityCounts() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT priority, COUNT(*) as count 
      FROM offline_requests 
      GROUP BY priority
    ''');

    final counts = <RequestPriority, int>{};
    for (final row in result) {
      final priority = RequestPriority.values[row['priority'] as int];
      final count = row['count'] as int;
      counts[priority] = count;
    }

    return counts;
  }
}
