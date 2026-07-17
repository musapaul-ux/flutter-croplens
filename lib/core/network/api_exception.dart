/// Normalized exception thrown by the API client so UI code never has to
/// know about Dio internals — it just catches ApiException and reads .message.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<FieldError> fieldErrors;

  ApiException(this.message, {this.statusCode, this.fieldErrors = const []});

  @override
  String toString() => message;
}

class FieldError {
  final String field;
  final String message;
  FieldError(this.field, this.message);
}
