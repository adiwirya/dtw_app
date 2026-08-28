import 'package:dtw_app/core/theme/app_theme.dart';
import 'package:dtw_app/core/widgets/success_modal.dart';
import 'package:flutter/material.dart';

/// The `SuccessModal` detail rows for the two busboy order success frames.
///
/// Shared rather than built inline at each call site: `SuccessModal.details`
/// describes *which order* is being confirmed, and the one time it was built
/// from anything other than the real order the busboy was shown a
/// confirmation for someone else's delivery. Both the in-flow screens and the
/// deep-link routes in `app_router.dart` go through here.

/// `Meja A-12  •  Downtown`, or just the table when there is no location.
///
/// A busboy delivery carries no zone/area name (see
/// `Delivery.toOrderCardData`), so the dot separator is only added when there
/// is a second value to separate — otherwise it dangles.
String _tableWithLocation(String tableName, String location) =>
    location.isEmpty ? tableName : '$tableName  •  $location';

/// Rows for `berhasil-ditambahkan`: the delivery a busboy just claimed.
List<SuccessModalDetail> claimedOrderDetails({
  required String tenantName,
  required String tableName,
  required String location,
  required String customerName,
}) {
  return [
    SuccessModalDetail(
      icon: Icons.storefront_outlined,
      label: 'Dari Tenant',
      value: tenantName,
      tileColor: AppColors.orderTileTenantBg,
      iconColor: AppColors.orderTileTenantIcon,
    ),
    SuccessModalDetail(
      icon: Icons.chair_outlined,
      label: 'Ke Meja',
      value: _tableWithLocation(tableName, location),
      tileColor: AppColors.successTint,
      iconColor: AppColors.successGreen,
    ),
    SuccessModalDetail(
      icon: Icons.person_outline,
      label: 'Pelanggan',
      value: customerName,
      tileColor: AppColors.orderTileCustomerBg,
      iconColor: AppColors.orderTileCustomerIcon,
    ),
  ];
}

/// Rows for `berhasil-ditambahkan-2`: the order a busboy just delivered.
///
/// Two rows rather than three — the tenant is not repeated once the delivery
/// has reached the table.
List<SuccessModalDetail> deliveredOrderDetails({
  required String tableName,
  required String customerName,
}) {
  return [
    SuccessModalDetail(
      icon: Icons.chair_outlined,
      label: 'Ke Meja',
      value: tableName,
      tileColor: AppColors.successTint,
      iconColor: AppColors.successGreen,
    ),
    SuccessModalDetail(
      icon: Icons.person_outline,
      label: 'Pelanggan',
      value: customerName,
      tileColor: AppColors.orderTileCustomerBg,
      iconColor: AppColors.orderTileCustomerIcon,
    ),
  ];
}

/// The `berhasil-ditambahkan-2` copy, shared by the deliver action and its
/// deep-link route.
abstract class DeliveredOrderCopy {
  static const title = 'Sampai dimeja';
  static const message = 'Pesanan telah berhasil diantar';
  static const confirmLabel = 'Lanjutkan';
}
