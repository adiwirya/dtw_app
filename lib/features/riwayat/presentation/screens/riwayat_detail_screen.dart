import 'package:dtw_app/core/exceptions.dart';
import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/features/riwayat/presentation/providers/riwayat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `detail-riwayat` frame: the history-entry detail page reached from a
/// Riwayat list row (`context.goNamed(AppRoutes.riwayatDetail,
/// pathParameters: {'entryId': ...})`).
///
/// Layout is the shared [CompletedDetailView]; only the `Informasi Pesanan`
/// "Tenan" value differs from `detail-selesai`. Back returns to the Riwayat
/// home (pop when poppable, else the parent route).
class RiwayatDetailScreen extends ConsumerWidget {
  const RiwayatDetailScreen({required this.entryId, super.key});

  /// Delivery id to load (a path parameter — see `app_router.dart`).
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(riwayatBoardProvider);
    final detail = ref.watch(riwayatDetailProvider(entryId));

    void onBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.riwayat);
      }
    }

    if (detail != null) {
      return CompletedDetailView(detail: detail, onBack: onBack);
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: boardAsync.isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    boardAsync.hasError
                        ? errorMessage(boardAsync.error!)
                        : 'Riwayat tidak ditemukan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
