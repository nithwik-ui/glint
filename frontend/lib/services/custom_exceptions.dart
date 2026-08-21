class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'No Internet Connection']);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, [this.statusCode = 400]);
  @override
  String toString() => 'API Error ($statusCode): $message';
}

class ServerException implements Exception {
  final String message;
  final int statusCode;
  ServerException(this.message, [this.statusCode = 500]);
  @override
  String toString() => 'Server Error ($statusCode): $message';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
  @override
  String toString() => 'Cache Error: $message';
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => 'Storage Error: $message';
}

class RecommendationException implements Exception {
  final String message;
  RecommendationException(this.message);
  @override
  String toString() => 'Recommendation Error: $message';
}
