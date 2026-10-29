/// The store pages the Share App message links to, stored at
/// `SystemConfiguration/StoreLinks`.
///
/// Kept identical to the admin panel's copy (khushiduaadmin/lib/models). A
/// missing document or a blank field falls back to the links below, so a
/// phone that has never been online still shares a working link.
class StoreLinks {
  static const String docId = 'StoreLinks';

  static const String defaultPlayStore =
      'https://play.google.com/store/apps/details?id=com.khushiidua.app&hl=en';
  static const String defaultAppStore =
      'https://apps.apple.com/us/app/khushii-dua/id6499438620';

  const StoreLinks({
    this.playStore = defaultPlayStore,
    this.appStore = defaultAppStore,
  });

  final String playStore;
  final String appStore;

  factory StoreLinks.fromMap(Map<String, dynamic>? map) {
    String pick(String key, String fallback) {
      final value = map?[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
    }

    return StoreLinks(
      playStore: pick('playStore', defaultPlayStore),
      appStore: pick('appStore', defaultAppStore),
    );
  }

  Map<String, dynamic> toMap() => {'playStore': playStore, 'appStore': appStore};
}
