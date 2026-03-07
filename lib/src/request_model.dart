import 'dart:convert';

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

  /// Optional HTTP headers (e.g. Authorization, Content-Type)
  /// Stored as a JSON string in SQLite
  final Map<String, String> headers;

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
    Map<String, String>? headers,
    required this.retryCount,
    required this.createdAt,
  }) : headers = headers ?? {};

  /// Convert request object to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'body': body,
      'headers': jsonEncode(headers),
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create request object from SQLite record
  factory OfflineRequest.fromMap(Map<String, dynamic> map) {
    Map<String, String> headers = {};
    if (map['headers'] != null && (map['headers'] as String).isNotEmpty) {
      final decoded =
          jsonDecode(map['headers'] as String) as Map<String, dynamic>;
      headers = decoded.map((k, v) => MapEntry(k, v.toString()));
    }
    return OfflineRequest(
      id: map['id'] as String,
      url: map['url'] as String,
      method: map['method'] as String,
      body: map['body'] as String,
      headers: headers,
      retryCount: map['retryCount'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
