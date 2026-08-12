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
