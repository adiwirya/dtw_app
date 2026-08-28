import 'package:dtw_app/core/models/completed_order_detail.dart';
import 'package:dtw_app/core/storage/secure_local_storage.dart';
import 'package:dtw_app/features/order/data/models/delivery.dart';
import 'package:dtw_app/features/order/data/repositories/busboy_delivery_repository.dart';
import 'package:dtw_app/features/riwayat/data/models/riwayat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'riwayat_provider.g.dart';

/// Currently selected Riwayat date tab, as an index into
/// `[hariIni, kemarin, tujuhHari]`. Kept as app state (not screen-local) so the
/// `/riwayat/kemarin` and `/riwayat/7-hari` route deep-links can switch the
/// in-place tab. Mirrors the Order tab provider.
@riverpod
class RiwayatTab extends _$RiwayatTab {
  @override
  int build() => 0;

  /// Select by index (0 = Hari Ini, 1 = Kemarin, 2 = 7 Hari Terakhir).
  // ignore: use_setters_to_change_properties
  void select(int index) => state = index;

  /// Select by [RiwayatRange].
  void selectRange(RiwayatRange range) => state = range.index;
}

/// The busboy's completed-delivery history, fetched once from
/// `GET /api/v1/busboy/deliveries?status=DELIVERED`. [riwayatDaysFrom]
/// buckets this same list by date for each [RiwayatRange] tab, and
/// [riwayatDetailProvider] looks a single entry up out of it.
// TODO(open-question): the busboy API has no date-range query param, so this
// fetches every DELIVERED delivery (unbounded, no pagination) and buckets by
// date client-side — fine for now, but will need a real range/pagination
// param from backend once delivery history grows large.
@riverpod
class RiwayatBoard extends _$RiwayatBoard {
  @override
  Future<List<Delivery>> build() async {
    final zoneId =
        await ref.watch(localStorageProvider).read(busboyZoneIdStorageKey);
    if (zoneId == null) {
      throw StateError('RiwayatBoard requires a zone-scoped session');
    }
    return ref
        .watch(busboyDeliveryRepositoryProvider)
        .fetchDeliveries(status: DeliveryStatus.delivered);
  }
}

/// Filters [deliveries] to those whose tenant (brand) name or table number
/// matches [query], case-insensitively. An empty/blank query matches
/// everything.
///
/// Client-side because `GET /api/v1/busboy/deliveries` takes no search param
/// and the list is already fetched in full. Applied BEFORE [riwayatDaysFrom]
/// so a date group that ends up with no matches disappears entirely rather
/// than rendering an empty header.
List<Delivery> riwayatSearch(List<Delivery> deliveries, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return deliveries;
  return [
    for (final delivery in deliveries)
      if (delivery.brandNames.toLowerCase().contains(needle) ||
          delivery.tableNumber.toLowerCase().contains(needle))
        delivery,
  ];
}

/// Buckets [deliveries] into date-grouped, newest-first [RiwayatDayGroup]s for
/// [range] — pure mapping, kept out of the notifier so it's trivially
/// testable on its own.
///
/// - [RiwayatRange.hariIni] → today's deliveries only.
/// - [RiwayatRange.kemarin] → yesterday's deliveries only.
/// - [RiwayatRange.tujuhHari] → the last 7 days (today inclusive).
List<RiwayatDayGroup> riwayatDaysFrom(
  List<Delivery> deliveries,
  RiwayatRange range,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final sevenDaysAgo = today.subtract(const Duration(days: 6));

  bool inRange(DateTime day) => switch (range) {
        RiwayatRange.hariIni => day == today,
        RiwayatRange.kemarin => day == yesterday,
        RiwayatRange.tujuhHari =>
          !day.isBefore(sevenDaysAgo) && !day.isAfter(today),
      };

  final byDay = <DateTime, List<Delivery>>{};
  for (final delivery in deliveries) {
    final day = delivery.riwayatDay;
    if (!inRange(day)) continue;
    (byDay[day] ??= []).add(delivery);
  }

  final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in sortedDays)
      RiwayatDayGroup(
        date: Delivery.formatDate(day),
        entries: [
          for (final delivery in byDay[day]!) delivery.toRiwayatEntry(),
        ],
      ),
  ];
}

/// Looks [entryId] (a delivery id) up out of the same list
/// [riwayatBoardProvider] holds — null while the board is still loading, has
/// errored, or the delivery isn't on it.
@riverpod
CompletedOrderDetail? riwayatDetail(Ref ref, String entryId) {
  final deliveries = ref.watch(riwayatBoardProvider).valueOrNull;
  if (deliveries == null) return null;
  for (final delivery in deliveries) {
    if (delivery.id == entryId) return delivery.toCompletedOrderDetail();
  }
  return null;
}
