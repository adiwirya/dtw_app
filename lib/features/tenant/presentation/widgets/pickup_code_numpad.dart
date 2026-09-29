import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The custom on-screen numpad for the "Verifikasi Pickup" pickup-code entry
/// screen (L4 — matches Figma exactly rather than reusing the forgot-password
/// OTP/`TextField` pattern). A 3-column grid: `1 2 3 / 4 5 6 / 7 8 9 /
/// (blank) 0 backspace`. Purely presentational — it holds no code state of
/// its own; the caller accumulates digits from [onDigit]/[onBackspace].
class PickupCodeNumpad extends StatelessWidget {
  const PickupCodeNumpad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
  });

  /// Called with the tapped digit, e.g. `'7'`.
  final ValueChanged<String> onDigit;

  /// Called when the backspace key is tapped.
  final VoidCallback onBackspace;

  static const List<List<String?>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    [null, '0', null],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _rows.length; r++) ...[
          Row(
            children: [
              for (var c = 0; c < _rows[r].length; c++)
                Expanded(
                  child: switch ((_rows[r][c], r == _rows.length - 1, c)) {
                    (null, true, 2) => _BackspaceKey(onPressed: onBackspace),
                    (null, _, _) => const SizedBox.shrink(),
                    (final key?, _, _) =>
                      _DigitKey(digit: key, onPressed: () => onDigit(key)),
                  },
                ),
            ],
          ),
          if (r != _rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onPressed});

  final String digit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              color: AppColors.neutral500,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
