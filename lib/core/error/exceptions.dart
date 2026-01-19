/// Represents exceptions that occur on the server.
class ServerException implements Exception {
  final String message;

  const ServerException(this.message);
}

/// Represents exceptions that occur while caching data.
class CacheException implements Exception {
  final String message;

  const CacheException(this.message);
}

/// Represents exceptions that occur during database operations.
class VectorDatabaseException implements Exception {
  final String message;

  const VectorDatabaseException(this.message);
}
