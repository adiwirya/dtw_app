import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Reusable single-line text field styled from the `login-default` cache.
///
/// Layout: a leading icon, the entry field, and an optional trailing widget
/// inside a 40px-high, 12px-radius, `#D0D3D9`-bordered box. Placeholder text is
/// `#667085` at 14pt.
///
/// The widget is icon-agnostic — callers pass an [IconData] for [leadingIcon].
/// When [obscureText] is true and no explicit [trailing] is given, a built-in
/// eye toggle is shown that flips obscuring on tap.
class AppInput extends StatefulWidget {
  const AppInput({
    this.controller,
    this.leadingIcon,
    this.hintText,
    this.label,
    this.obscureText = false,
    this.trailing,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Controls the text being edited. Owned by the caller.
  final TextEditingController? controller;

  /// Leading glyph shown at the start of the field (e.g. user / lock).
  final IconData? leadingIcon;

  /// Placeholder shown when the field is empty.
  final String? hintText;

  /// Optional label rendered above the field.
  final String? label;

  /// Whether to obscure the entered text (passwords). When true and [trailing]
  /// is null, a reveal/hide eye toggle is shown.
  final bool obscureText;

  /// Explicit trailing widget. Overrides the built-in password eye toggle.
  final Widget? trailing;

  /// Whether the field accepts input.
  final bool enabled;

  /// Keyboard type for the entry field.
  final TextInputType? keyboardType;

  /// Action button shown on the soft keyboard.
  final TextInputAction? textInputAction;

  /// Focus node for the entry field.
  final FocusNode? focusNode;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  Widget? _buildTrailing() {
    if (widget.trailing != null) return widget.trailing;
    if (!widget.obscureText) return null;
    return _EyeToggle(
      obscured: _obscured,
      onPressed: () => setState(() => _obscured = !_obscured),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trailing = _buildTrailing();

    // TODO(open-question): Open Sans isn't bundled yet; hint/text fall back to
    // the default family until the font is added.
    const hintStyle = TextStyle(
      color: AppColors.neutral500,
      fontSize: 14,
      height: 1,
    );

    final field = Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (widget.leadingIcon != null) ...[
            Icon(widget.leadingIcon, size: 20, color: AppColors.neutral500),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              obscureText: _obscured,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 14,
                height: 1,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hintText,
                hintStyle: hintStyle,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: const TextStyle(
            color: AppColors.neutral900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        // Obscured -> offer "reveal"; revealed -> offer "hide".
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.neutral500,
      ),
    );
  }
}
