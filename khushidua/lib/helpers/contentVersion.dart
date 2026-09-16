/// Pure cache-freshness logic for the content repository, kept free of
/// Firebase so it can be unit tested.
library;

/// Where content should be read from on this launch.
enum ContentSource {
  /// The on-device Firestore cache; costs no reads and needs no network.
  cache,

  /// The server; the cache is refreshed as a side effect.
  server,
}

/// How long cached content is trusted without a server check, even when the
/// version says nothing changed. A safety net for an admin save path that
/// forgets to bump the version.
const Duration kContentMaxAge = Duration(hours: 24);

/// Decides where to read content from.
///
/// [remoteVersion] is null when the manifest could not be read (offline, or
/// the document does not exist yet). [fetchedAt] is null when this device has
/// never completed a server load.
ContentSource decideContentSource({
  required int? localVersion,
  required int? remoteVersion,
  required DateTime? fetchedAt,
  required DateTime now,
}) {
  // Never loaded: there is nothing in the cache worth trusting.
  if (fetchedAt == null || localVersion == null) return ContentSource.server;

  // Offline, or no manifest yet: serve what is on disk rather than showing
  // nothing. The next launch with a connection will reconcile.
  if (remoteVersion == null) return ContentSource.cache;

  if (remoteVersion != localVersion) return ContentSource.server;

  // A clock that jumped backwards counts as stale, not as fresh forever.
  final age = now.difference(fetchedAt);
  if (age.isNegative || age > kContentMaxAge) return ContentSource.server;

  return ContentSource.cache;
}
