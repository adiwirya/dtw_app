import 'package:dtw_app/core/notifications/new_order_alerts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (label, config) in [
    ('tenant', NewOrderAlertsConfig.tenant),
    ('busboy', NewOrderAlertsConfig.busboy),
  ]) {
    group(label, () {
      // A typo in the asset path doesn't throw anywhere the session can
      // see it — the chime just never plays. `audioplayers` prefixes
      // `AssetSource` with `assets/`, so this is the exact string it
      // resolves.
      test('the chime asset is actually bundled', () async {
        final data = await rootBundle.load('assets/${config.chimeAsset}');

        expect(data.lengthInBytes, greaterThan(0));
        // A RIFF/WAVE header, not an HTML error page or a stray text file.
        final header = String.fromCharCodes(data.buffer.asUint8List(0, 12));
        expect(header.substring(0, 4), 'RIFF');
        expect(header.substring(8, 12), 'WAVE');
      });

      // Android reads a channel sound from `res/raw` by bare resource name.
      // The notification path and the in-app path must be the same sound,
      // so the session doesn't learn two different noises for one event.
      test('the res/raw resource name matches the bundled file', () {
        expect(config.chimeAsset, 'sounds/${config.channelSoundResource}.wav');
      });

      // The channel's sound is immutable once created, so retuning the
      // chime without bumping this leaves every existing install on the
      // old one.
      test('the channel id is versioned', () {
        expect(config.channelId, matches(RegExp(r'_v\d+$')));
      });
    });
  }

  // Each flavor needs its own channel and sound: a shared one would mean a
  // busboy session hears/creates the tenant's chime/permission prompt (or
  // vice versa), and a channel can't be repointed at a different sound after
  // creation anyway.
  test('tenant and busboy use distinct channels and sounds', () {
    const tenant = NewOrderAlertsConfig.tenant;
    const busboy = NewOrderAlertsConfig.busboy;

    expect(tenant.channelId, isNot(busboy.channelId));
    expect(tenant.chimeAsset, isNot(busboy.chimeAsset));
    expect(tenant.channelSoundResource, isNot(busboy.channelSoundResource));
  });
}
