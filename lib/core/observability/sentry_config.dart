/// Sentry project connection constants — `dtw-order` on the `adis-42` org.
///
/// [dsn] is a public client-side identifier, not a secret — same trust level
/// as `ReverbConfig.appKey`: safe to ship in the built app, it only lets a
/// client *send* events, never read them back.
class SentryConfig {
  const SentryConfig._();

  static const dsn =
      'https://621e2842516f44f44a00446c9192b2e2@o4512054511665152.ingest.de.sentry.io/4512054545678416';
}
