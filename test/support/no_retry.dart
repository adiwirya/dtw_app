/// Riverpod 3 retries a provider that fails during build with exponential
/// backoff. Tests that assert on the failure (an `AsyncError`, a thrown
/// `ApiException`) pass this as `retry:` so the first error is final and no
/// retry timer is left pending.
Duration? noRetry(int retryCount, Object error) => null;
