import 'package:flutter/foundation.dart';

/// The three Riwayat (history) date ranges, matching the `SegmentedTabBar`
/// order: Hari Ini / Kemarin / 7 Hari Terakhir.
enum RiwayatRange { hariIni, kemarin, tujuhHari }

/// A single completed-order row in the Riwayat list.
///
/// Deliberately a plain value object decoupled from any repository/DTO — the
/// real history data source is an Open Question (see work item L3/L5). When the
/// real source lands, map the domain entity onto this or construct it directly.
@immutable
class RiwayatEntry {
  const RiwayatEntry({
    required this.id,
    required this.time,
    required this.statusLabel,
    required this.tenantName,
    required this.tableName,
    required this.location,
  });

  /// The real delivery id — what the `detail-riwayat` route targets.
  final String id;

  /// Completion time, e.g. `10:45`. Rendered top-left of the row.
  final String time;

  /// Order state label, e.g. `Selesai`. Rendered top-right of the row.
  final String statusLabel;

  /// Source tenant/merchant name, e.g. `KFC Fried Chicken` (row title).
  final String tenantName;

  /// Destination table label, e.g. `Meja A-12`.
  final String tableName;

  /// Destination area/zone, e.g. `Downtown` (shown after the table name).
  final String location;
}

/// A date-grouped bucket of [RiwayatEntry] rows, headed by the date and a task
/// count (e.g. `12 Mei 2026` — `3 Tugas`). The `7 Hari Terakhir` tab renders
/// several of these stacked; `Hari Ini` / `Kemarin` render one.
@immutable
class RiwayatDayGroup {
  const RiwayatDayGroup({
    required this.date,
    required this.entries,
  });

  /// Human date header, e.g. `12 Mei 2026`.
  final String date;

  /// The completed-order rows for this date.
  final List<RiwayatEntry> entries;

  /// Task-count label shown at the right of the date header (`3 Tugas`).
  String get taskLabel => '${entries.length} Tugas';
}
