class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  // Screens show errors with toString() — keep it to the server's message.
  String toString() => message;
}
