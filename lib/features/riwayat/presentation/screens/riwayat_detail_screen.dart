import 'package:dtw_app/core/router/app_router.dart';
import 'package:dtw_app/core/widgets/completed_detail_view.dart';
import 'package:dtw_app/features/riwayat/presentation/providers/riwayat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The `detail-riwayat` frame: the history-entry detail page reached from a
/// Riwayat list row (`context.goNamed(AppRoutes.riwayatDetail)`).
///
/// Layout is the shared [CompletedDetailView]; only the `Informasi Pesanan`
/// "Tenan" value differs from `detail-selesai`. Back returns to the Riwayat
/// home (pop when poppable, else the parent route).
class RiwayatDetailScreen extends ConsumerWidget {
  const RiwayatDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(riwayatDetailProvider);
    return CompletedDetailView(
      detail: detail,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.riwayat);
        }
      },
    );
  }
}
