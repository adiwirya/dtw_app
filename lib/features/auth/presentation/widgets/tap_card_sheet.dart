import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/nfc/card_reader_service.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/core/widgets/secondary_button.dart';
import 'package:dtw_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the tap-card login sheet and completes when it closes (after a
/// successful login, or when the user cancels).
///
/// Not in the Figma yet — the design only has the "Masuk dengan Tap Kartu"
/// button, so this is a stand-in built from the app's existing modal styling.
Future<void> showTapCardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const TapCardSheet(),
  );
}

enum _Phase { waiting, loading, error }

class TapCardSheet extends ConsumerStatefulWidget {
  const TapCardSheet({super.key});

  @override
  ConsumerState<TapCardSheet> createState() => _TapCardSheetState();
}

class _TapCardSheetState extends ConsumerState<TapCardSheet> {
  _Phase _phase = _Phase.waiting;
  String? _error;
  late final CardReaderService _reader;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _reader = ref.read(cardReaderServiceProvider);
    unawaited(_start());
  }

  @override
  void dispose() {
    _closing = true;
    unawaited(_reader.cancel());
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.waiting;
      _error = null;
    });

    if (await _reader.availability() != CardReaderAvailability.available) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = 'NFC belum aktif. Aktifkan NFC di pengaturan perangkat.';
      });
      return;
    }

    final String uid;
    try {
      uid = await _reader.readCardUid();
    } on CardReadException catch (error) {
      if (!mounted || _closing) return;
      setState(() {
        _phase = _Phase.error;
        _error = error.message;
      });
      return;
    }
    if (!mounted) return;

    setState(() => _phase = _Phase.loading);
    await ref.read(authControllerProvider.notifier).loginWithCard(cardUid: uid);
    if (!mounted) return;

    final error = ref.read(authControllerProvider).error;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _phase = _Phase.error;
      _error = error is AuthException
          ? error.message
          : 'Terjadi kesalahan. Coba lagi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isError = _phase == _Phase.error;
    final isLoading = _phase == _Phase.loading;
    final accent = isError ? AppColors.dangerRed : AppColors.successGreen;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.nfc,
                size: 40,
                color: accent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tempelkan Kartu',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isError
                  ? _error!
                  : isLoading
                  ? 'Memeriksa kartu...'
                  : 'Dekatkan kartu ke bagian belakang perangkat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? AppColors.dangerRed : AppColors.neutral500,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (isError) ...[
                PrimaryButton(label: 'Coba Lagi', onPressed: _start),
                const SizedBox(height: 12),
              ],
              SecondaryButton(
                label: 'Batal',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
