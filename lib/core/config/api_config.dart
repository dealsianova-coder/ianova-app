class IanovaApiConfig {
  IanovaApiConfig._();

  static const String baseUrl = 'http://127.0.0.1:8080';

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
