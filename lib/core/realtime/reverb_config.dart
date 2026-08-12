/// Connection constants for the Downtown CMS Laravel Reverb server.
///
/// [appKey] is a Pusher/Reverb *app key* — a public client-side identifier
/// (not a secret), the same trust level as [host] itself.
class ReverbConfig {
  const ReverbConfig._();

  static const host = 'dtw-cms.gadingemerald.com';
  static const appKey = 'qvata3lm1xtqpocb9g2i';
  static const useTls = true;

  /// Assumed to be reverse-proxied on the same port as the REST API (443)
  /// since Reverb runs on "the same domain" per the backend team — verify on
  /// the first real connection attempt; if it fails to connect, the actual
  /// Reverb port needs to be obtained separately.
  static const port = 443;

  static String get authEndpoint => 'https://$host/broadcasting/auth';
}
