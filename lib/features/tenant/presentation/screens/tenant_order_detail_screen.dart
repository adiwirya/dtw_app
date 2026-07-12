import 'package:dtw_app/features/tenant/presentation/screens/tenant_order_screen.dart';
import 'package:flutter/material.dart';

/// The `menu-order-baru-2` frame — the order view reached from tapping an Order
/// Baru card.
///
/// Interpretation (see report): unlike the busboy `menu-order-baru-2`, which
/// is a dedicated "Detail Pesanan" screen, the tenant `menu-order-baru-2`
/// reference is pixel-identical to the tenant Order home on the Baru sub-tab
/// (same green header, the Baru/Diproses/Selesai tabs, two Tolak/Terima cards).
/// It is a prototype navigation-target duplicate of `menu-order-baru`, so this
/// screen reproduces it by delegating to [TenantOrderScreen] seeded to Baru
/// (no duplicated layout to drift from the home).
class TenantOrderDetailScreen extends StatelessWidget {
  const TenantOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => const TenantOrderScreen();
}
