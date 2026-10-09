class IanovaApiConfig {
  IanovaApiConfig._();

  /// Override at build time:
  ///   flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static final String baseUrl = _rawBaseUrl.replaceAll(RegExp(r'/+$'), '');

  static String imageUrl(String image) {
    final value = image.trim();

    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalized = value.startsWith('/') ? value.substring(1) : value;

    return '$baseUrl/$normalized';
  }
}
