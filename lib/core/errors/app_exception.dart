class AppException implements Exception {
  const AppException({required this.message, this.code, this.details});

  final String message;
  final String? code;
  final Object? details;

  @override
  String toString() {
    if (code == null) {
      return 'AppException: $message';
    }

    return 'AppException($code): $message';
  }
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Connessione non disponibile. Riprova tra poco.',
    super.code = 'network_error',
    super.details,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Non hai i permessi per eseguire questa azione.',
    super.code = 'unauthorized',
    super.details,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'validation_error',
    super.details,
  });
}

class UnknownAppException extends AppException {
  const UnknownAppException({
    super.message = 'Si è verificato un errore imprevisto.',
    super.code = 'unknown_error',
    super.details,
  });
}
