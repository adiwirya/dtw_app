/// Connection constants for the Downtown CMS Laravel Reverb server.
///
/// [appKey] is a Pusher/Reverb *app key* — a public client-side identifier
/// (not a secret), the same trust level as [host] itself.
class ReverbConfig {
  const ReverbConfig._();

  static const host = 'dtw-cms.gadingemerald.com';
  static const appKey = 'qvata3lm1xtqpocb9g2i';
  static const useTls = true;

  static const port = 443;

  static String get authEndpoint => 'https://$host/broadcasting/auth';
}
