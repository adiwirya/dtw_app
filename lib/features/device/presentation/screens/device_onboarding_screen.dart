import 'dart:async';

import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/flavor.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/primary_button.dart';
import 'package:dtw_app/features/device/data/repositories/device_repository.dart';
import 'package:dtw_app/features/device/data/services/device_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one-time, pre-login device-onboarding gate (`POST
/// /v1/devices/register`) — see
/// `docs/superpowers/specs/2026-09-28-device-onboarding-design.md`.
///
/// Auto-registers on mount; no user input, no back navigation (there is
/// nowhere to go back to — this precedes login entirely). On success,
/// persists [deviceRegisteredStorageKey] and flips
/// [deviceRegisteredProvider], which the router's redirect reacts to. On
/// failure, shows the error message with a "Coba Lagi" retry — no skip.
class DeviceOnboardingScreen extends ConsumerStatefulWidget {
  const DeviceOnboardingScreen({super.key});

  @override
  ConsumerState<DeviceOnboardingScreen> createState() =>
      _DeviceOnboardingScreenState();
}

class _DeviceOnboardingScreenState
    extends ConsumerState<DeviceOnboardingScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_register());
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final identity = ref.read(deviceIdentityProvider);
      final deviceId = await identity.deviceId();
      final fcmToken = await identity.fcmToken();
      if (deviceId == null || fcmToken == null) {
        throw StateError('device id/fcm token unavailable');
      }
      await ref
          .read(deviceRepositoryProvider)
          .register(deviceId: deviceId, fcmToken: fcmToken);
      await ref
          .read(localStorageProvider)
          .write(deviceRegisteredStorageKey, 'true');
      if (!mounted) return;
      ref.read(deviceRegisteredProvider.notifier).state = true;
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errorMessage(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final failed = _error != null;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.smartphone,
                  size: 32,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                failed ? 'Gagal Menyiapkan Device' : 'Menyiapkan Device',
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ??
                    'Mendaftarkan device ini ke server, mohon tunggu '
                        'sebentar.',
                style: TextStyle(
                  color: failed ? AppColors.dangerRed : AppColors.neutral500,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (failed)
                PrimaryButton(
                  label: 'Coba Lagi',
                  onPressed: _loading ? null : () => unawaited(_register()),
                )
              else if (_loading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.successGreen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
