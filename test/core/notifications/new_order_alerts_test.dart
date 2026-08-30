import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A typo in the asset path doesn't throw anywhere the tenant can see it —
  // the chime just never plays. `audioplayers` prefixes `AssetSource` with
  // `assets/`, so this is the exact string it resolves.
  test('the chime asset is actually bundled', () async {
    final data = await rootBundle.load(
      'assets/${PluginNewOrderAlerts.chimeAsset}',
    );

    expect(data.lengthInBytes, greaterThan(0));
    // A RIFF/WAVE header, not an HTML error page or a stray text file.
    final header = String.fromCharCodes(
      data.buffer.asUint8List(0, 12),
    );
    expect(header.substring(0, 4), 'RIFF');
    expect(header.substring(8, 12), 'WAVE');
  });

  // Android reads a channel sound from `res/raw` by bare resource name. The
  // notification path and the in-app path must be the same sound, so the
  // tenant doesn't learn two different noises for one event.
  test('the res/raw resource name matches the bundled file', () {
    expect(PluginNewOrderAlerts.chimeAsset, 'sounds/new_order.wav');
  });

  // The channel's sound is immutable once created, so retuning the chime
  // without bumping this leaves every existing install on the old one.
  test('the channel id is versioned', () {
    expect(PluginNewOrderAlerts.channelId, matches(RegExp(r'_v\d+$')));
  });
}
