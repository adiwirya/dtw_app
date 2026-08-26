/// Connection constants for the Downtown CMS Laravel Reverb server.
///
/// [appKey] is a Pusher/Reverb *app key* — a public client-side identifier
/// (not a secret), the same trust level as [host] itself.
///
/// [host] (the WebSocket server) and [authHost] (the `/broadcasting/auth`
/// handshake) are on separate domains — confirmed with the backend team: the
/// Reverb socket was split out to its own host, while private-channel auth is
/// still handled by the main Laravel app.
class ReverbConfig {
  const ReverbConfig._();

  static const host = 'dtw-ws.gadingemerald.com';
  static const authHost = 'dtw-cms.gadingemerald.com';
  static const appKey = 'qvata3lm1xtqpocb9g2i';
  static const useTls = true;

  static const port = 443;

  static String get authEndpoint => 'https://$authHost/broadcasting/auth';
}
