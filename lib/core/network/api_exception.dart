class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException() : super('No internet connection');
}

class TimeoutException extends ApiException {
  TimeoutException() : super('Request timeout');
}

class ServerException extends ApiException {
  ServerException([String message = 'Server error'])
      : super(message, statusCode: 500);
}