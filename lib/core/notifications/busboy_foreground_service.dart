import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'busboy_foreground_service.g.dart';

/// `flutter_foreground_task` requires a task handler, but this service has
/// no periodic work for it to do — see [BusboyForegroundService]'s doc for
/// why simply running one is the whole point.
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_NoOpTaskHandler());
}

class _NoOpTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Keeps the app process out of Android's background/Doze process-kill path
/// while a busboy is logged in, by running a foreground service with a
/// small persistent notification — Android's contract for "don't freeze
/// me" once there is no Activity on screen.
///
/// Without this, a backgrounded session can be suspended entirely — and
/// with it every Dart-side realtime handling this app already has for a
/// dropped socket (`OrderBoardNotifier`'s `delivery.created` listener). The
/// task handler this starts does nothing on its own; the OS-level side
/// effect of an active foreground service — the whole process it belongs to
/// becomes a much harder kill target — is the only thing this is for. The
/// real work (the Reverb socket, the order board) keeps running on the main
/// isolate exactly as it does today. See `TenantForegroundService` for the
/// tenant-side equivalent this mirrors.
///
/// **Android only, by decision** — same reasoning as `TenantForegroundService`:
/// iOS enforces its own background suspension regardless of anything an app
/// declares, so there is no equivalent lever to pull there.
abstract class BusboyForegroundService {
  /// Starts the service. Safe to call when already running.
  Future<void> start();

  /// Stops the service. Safe to call when not running.
  Future<void> stop();
}

class PluginBusboyForegroundService implements BusboyForegroundService {
  PluginBusboyForegroundService({bool? isAndroid})
    : _isAndroid = isAndroid ?? Platform.isAndroid {
    if (_isAndroid) _init();
  }

  static const _serviceId = 1001;
  static const _channelId = 'busboy_session_v1';
  static const _channelName = 'Sesi Busboy Aktif';

  final bool _isAndroid;
  var _initialized = false;

  void _init() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription:
            'Menjaga koneksi order tetap aktif di latar belakang.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // No periodic work — see the class doc. `nothing()` skips
        // `onRepeatEvent` entirely instead of ticking for no reason.
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> start() async {
    if (!_isAndroid) return;
    // Android 13+ gates the persistent notification behind a runtime grant,
    // same as `TenantForegroundService` — declining still leaves the service
    // (and the process-kill protection) running, just without the icon.
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'DTW Busboy Aktif',
      notificationText: 'Memantau order masuk...',
      callback: _startCallback,
    );
  }

  @override
  Future<void> stop() async {
    if (!_isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}

@Riverpod(keepAlive: true)
BusboyForegroundService busboyForegroundService(Ref ref) =>
    PluginBusboyForegroundService();
