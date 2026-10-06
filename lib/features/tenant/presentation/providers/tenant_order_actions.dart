import 'dart:async';

import 'package:dtw_app/core/printing/receipt_printer_service.dart';
import 'package:dtw_app/features/tenant/data/models/tenant_order.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_branch_provider.dart';
import 'package:dtw_app/features/tenant/presentation/providers/tenant_order_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Accepts [orderId], then prints its bon — the "Terima" action's whole
/// point: the kitchen only learns about the order once the printer spits out
/// a physical ticket. Shared by the Order list card and the order detail
/// screen so both behave identically.
///
/// Printing is fire-and-forget after a successful accept: a busy/out-of-paper
/// printer must never undo (or block the UI on) an accept the backend already
/// recorded.
Future<void> acceptOrderAndPrint(WidgetRef ref, String orderId) async {
  TenantOrder? order;
  for (final candidate
      in ref.read(tenantOrderBoardProvider).valueOrNull ??
          const <TenantOrder>[]) {
    if (candidate.id == orderId) {
      order = candidate;
      break;
    }
  }

  await ref.read(tenantOrderBoardProvider.notifier).accept(orderId);

  final branch = ref.read(currentTenantBranchProvider).valueOrNull;
  if (order != null && branch != null) {
    unawaited(
      ref
          .read(receiptPrinterServiceProvider)
          .printOrder(
            order,
            brandName: branch.brandName,
            areaName: branch.areaName,
            locationCode: branch.locationCode,
          )
          .catchError((_) {}),
    );
  }
}
