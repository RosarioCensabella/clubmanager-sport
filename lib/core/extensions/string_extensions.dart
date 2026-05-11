extension StringExtensions on String {
  String get trimmed => trim();

  bool get isBlank => trim().isEmpty;

  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return emailRegex.hasMatch(trim());
  }

  String get capitalized {
    final value = trim();

    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}