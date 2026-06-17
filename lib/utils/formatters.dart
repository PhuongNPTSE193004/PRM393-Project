/// Formats a price as Vietnamese-grouped digits, e.g. 7600000 -> "7.600.000".
///
/// Does not append the currency symbol (đ) — callers append it so the
/// symbol's styling (color, size) can differ from the number's.
String formatVnd(double price) {
  final digits = price.toStringAsFixed(0);
  final reversed = digits.split('').reversed.toList();

  final grouped = <String>[];
  for (var i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) grouped.add('.');
    grouped.add(reversed[i]);
  }

  return grouped.reversed.join();
}