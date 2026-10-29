/// The builds the update prompt compares against, stored at
/// `SystemConfiguration/AppVersion`.
///
/// Kept identical to the admin panel's copy (khushiduaadmin/lib/models).
/// Numbers are build numbers (the part after + in pubspec's version, which
/// is Android's versionCode and iOS's CFBundleVersion). A missing document
/// or field is 0, which never prompts.
class AppVersion {
  static const String docId = 'AppVersion';

  const AppVersion({
    this.androidLatest = 0,
    this.androidMin = 0,
    this.iosLatest = 0,
    this.iosMin = 0,
  });

  /// Builds below this see a prompt they can put off.
  final int androidLatest;
  final int iosLatest;

  /// Builds below this see a prompt they cannot close.
  final int androidMin;
  final int iosMin;

  factory AppVersion.fromMap(Map<String, dynamic>? map) {
    int read(String key) {
      final value = map?[key];
      return value is num ? value.toInt() : 0;
    }

    return AppVersion(
      androidLatest: read('androidLatest'),
      androidMin: read('androidMin'),
      iosLatest: read('iosLatest'),
      iosMin: read('iosMin'),
    );
  }

  Map<String, dynamic> toMap() => {
    'androidLatest': androidLatest,
    'androidMin': androidMin,
    'iosLatest': iosLatest,
    'iosMin': iosMin,
  };
}
