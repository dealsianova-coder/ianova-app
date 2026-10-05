/// Formats a price as "KSh 3,500". Cents only show when there are any.
String formatKsh(num value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  final hasCents = absolute % 1 != 0;
  final parts = absolute.toStringAsFixed(hasCents ? 2 : 0).split('.');
  final digits = parts[0];
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  final cents = parts.length > 1 ? '.${parts[1]}' : '';

  return 'KSh $sign$buffer$cents';
}
