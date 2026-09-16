import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/contentVersion.dart';

void main() {
  final now = DateTime(2026, 9, 16, 12);
  final anHourAgo = now.subtract(const Duration(hours: 1));

  ContentSource decide({
    int? local = 3,
    int? remote = 3,
    DateTime? fetchedAt,
    bool neverFetched = false,
  }) => decideContentSource(
    localVersion: local,
    remoteVersion: remote,
    fetchedAt: neverFetched ? null : (fetchedAt ?? anHourAgo),
    now: now,
  );

  test('a device that has never loaded goes to the server', () {
    expect(decide(neverFetched: true), ContentSource.server);
    expect(decide(local: null), ContentSource.server);
  });

  test('an unchanged, recent version is served from the cache', () {
    expect(decide(), ContentSource.cache);
  });

  test('a bumped version goes to the server', () {
    expect(decide(remote: 4), ContentSource.server);
  });

  test('a lower remote version also refetches, rather than trusting disk', () {
    // A reset manifest must not leave devices on content newer than the
    // server's idea of current.
    expect(decide(remote: 1), ContentSource.server);
  });

  test('offline or missing manifest serves the cache instead of nothing', () {
    expect(decide(remote: null), ContentSource.cache);
  });

  test('content older than the max age is refetched even if unchanged', () {
    final stale = now.subtract(kContentMaxAge + const Duration(minutes: 1));
    expect(decide(fetchedAt: stale), ContentSource.server);
  });

  test('content exactly at the max age is still trusted', () {
    expect(decide(fetchedAt: now.subtract(kContentMaxAge)), ContentSource.cache);
  });

  test('a fetch time in the future counts as stale', () {
    final future = now.add(const Duration(days: 2));
    expect(decide(fetchedAt: future), ContentSource.server);
  });
}
