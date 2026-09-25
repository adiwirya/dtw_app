import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared "board failed to load" state: the [message] (see `errorMessage` in
/// `core/exceptions.dart`) plus a "Coba lagi" button wired to [onRetry] —
/// typically `() => ref.invalidate(someProvider)`.
///
/// Every screen that reads an `AsyncValue`'s `error:` branch renders it
/// through this instead of a bare `Text`, so a failed initial load is never a
/// dead end: the timeouts in `dio_provider.dart` guarantee the request itself
/// doesn't hang, but without a retry affordance the user still had no way
/// forward except leaving and re-entering the screen.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neutral500,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
