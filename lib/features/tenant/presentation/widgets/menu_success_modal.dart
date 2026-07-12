import 'dart:async';

import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Presents the `berhasil-ditambahkan` menu-added confirmation as a centered
/// dialog. It auto-dismisses after [duration] and then invokes [onConfirm] so
/// the caller can advance to `menu-berhasil-ditambahkan`. Also dismissible by
/// tapping the scrim.
Future<void> showMenuSuccessModal(
  BuildContext context, {
  required VoidCallback onConfirm,
  Duration duration = const Duration(milliseconds: 1400),
}) {
  var advanced = false;
  void advance() {
    if (advanced) return;
    advanced = true;
    onConfirm();
  }

  final future = showDialog<void>(
    context: context,
    builder: (_) => const MenuSuccessModal(),
  ).then((_) => advance());

  Timer(duration, () {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  });

  return future;
}

/// The `berhasil-ditambahkan` modal body: a success check ring wreathed in
/// confetti flecks over a centered "Menu baru berhasil ditambahkan" caption.
///
/// Public so it can be pumped directly in golden tests.
class MenuSuccessModal extends StatelessWidget {
  const MenuSuccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConfettiRing(),
            SizedBox(height: 24),
            Text(
              'Menu baru berhasil ditambahkan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The check ring plus a scatter of confetti flecks (`berhasil-ditambahkan`).
class _ConfettiRing extends StatelessWidget {
  const _ConfettiRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti flecks around the ring.
          const _Fleck(left: 6, top: 20, color: AppColors.starAmber),
          const _Fleck(left: 20, top: 60, color: AppColors.successGreen),
          const _Fleck(left: 2, top: 44, color: AppColors.neutral100),
          const _Fleck(right: 8, top: 14, color: AppColors.successGreen),
          const _Fleck(right: 2, top: 46, color: AppColors.starAmber),
          const _Fleck(right: 22, top: 66, color: AppColors.neutral100),
          const _Fleck(left: 40, top: 4, color: AppColors.neutral100),
          const _Fleck(right: 44, top: 2, color: AppColors.starAmber),
          // The check ring.
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 32,
                color: AppColors.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fleck extends StatelessWidget {
  const _Fleck({
    required this.color,
    this.left,
    this.right,
    this.top,
  });

  final Color color;
  final double? left;
  final double? right;
  final double? top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: 0.6,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}
