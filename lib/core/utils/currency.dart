/// Formats an integer rupiah amount as `Rp35.000` (thousands separated by
/// `.`). Shared by every feature that renders a rupiah amount — do not
/// re-implement this per feature.
String formatRupiah(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp$buffer';
}

/// Inverse of [formatRupiah]: `'Rp3.000'` -> `3000`. `null` (no add-on price,
/// i.e. `Gratis`) -> `0`. Strips everything but digits, so it tolerates the
/// `Rp`/`.` formatting either way.
int parseRupiah(String? formatted) {
  if (formatted == null) return 0;
  final digits = formatted.replaceAll(RegExp('[^0-9]'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}
