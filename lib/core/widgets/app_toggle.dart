import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The green pill switch used across every tenant screen: the menu-item card
/// "Aktif" toggle, the per-item order availability toggle, the varian rule
/// toggles ("Wajib Dipilih" / "Pilih Lebih dari Satu") and the admin
/// online/offline control.
///
/// Kept intentionally generic (in `core/widgets`) because 4+ tenant widgets
/// reuse it. Pass a null [onChanged] to render the disabled state.
///
/// Cached design values (`menu-saya` / `tambah-varian` frames): 44x24 track,
/// full-radius, success-green when on / `#E4E7EC` when off, 20px white knob
/// with a 2px inset.
class AppToggle extends StatelessWidget {
  const AppToggle({
    required this.value,
    this.onChanged,
    this.semanticLabel,
    this.offColor,
    super.key,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the toggled value when tapped. Null disables the control.
  final ValueChanged<bool>? onChanged;

  /// Optional semantics label for accessibility / test lookup.
  final String? semanticLabel;

  /// Off-state track colour. Defaults to the neutral
  /// [AppColors.toggleTrackOff]; the order-rejection row passes a red track to
  /// signal a rejected item (`konfirmasi-pesanan`).
  final Color? offColor;

  static const double _trackWidth = 44;
  static const double _trackHeight = 24;
  static const double _knob = 20;
  static const double _inset = 2;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final track = value
        ? AppColors.successGreen
        : (offColor ?? AppColors.toggleTrackOff);

    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: _enabled,
      button: true,
      child: Opacity(
        opacity: _enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: _trackWidth,
            height: _trackHeight,
            padding: const EdgeInsets.all(_inset),
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(_trackHeight),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
