import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Create required tables on first launch
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_requests (
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        method TEXT NOT NULL,
        body TEXT NOT NULL,
        retryCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
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
      orderBy: 'createdAt ASC',
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
}
