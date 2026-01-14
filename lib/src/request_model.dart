/// Represents a single offline API request
/// that could not be sent due to no internet.
///
/// This object is stored in SQLite and later
/// synced automatically when internet is available.
class OfflineRequest {
  /// Unique identifier for the request
  /// Used to track and delete it after successful sync
  final String id;

  /// API endpoint URL
  final String url;

  /// HTTP method (POST, PUT, DELETE)
  final String method;

  /// Request body stored as JSON string
  ///
  /// SQLite does not support Map types directly,
  /// so we serialize the body before saving.
  final String body;

  /// Number of retry attempts made for this request
  final int retryCount;

  /// Timestamp when the request was created
  ///
  /// Used to preserve FIFO (First-In-First-Out) order
  final DateTime createdAt;

  OfflineRequest({
    required this.id,
    required this.url,
    required this.method,
    required this.body,
    required this.retryCount,
    required this.createdAt,
  });

  /// Convert request object to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'body': body,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create request object from SQLite record
  factory OfflineRequest.fromMap(Map<String, dynamic> map) {
    return OfflineRequest(
      id: map['id'] as String,
      url: map['url'] as String,
      method: map['method'] as String,
      body: map['body'] as String,
      retryCount: map['retryCount'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
