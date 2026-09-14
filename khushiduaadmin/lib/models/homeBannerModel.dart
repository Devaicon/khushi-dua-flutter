/// The app's home screen banner, stored at `SystemConfiguration/HomeBanner`.
///
/// `title` and `subtitle` are keyed by the language names the app uses for its
/// language picker ("English", "Arabic", …). English is the fallback, so a
/// banner written only in English still reaches every user.
class HomeBannerModel {
  static const String docId = 'HomeBanner';
  static const String fallbackLanguage = 'English';

  /// The languages the app offers, in the order the admin form shows them.
  /// English first because it is the required one.
  static const List<String> languages = [
    'English',
    'Arabic',
    'Bengali',
    'French',
    'German',
    'Gujarati',
    'Hindi',
    'Indonesian',
    'Japanese',
    'Malay',
    'Mandarin',
    'Marathi',
    'Portuguese',
    'Punjabi',
    'Russian',
    'Sindhi',
    'Spanish',
    'Tamil',
    'Telugu',
    'Turkish',
    'Urdu',
  ];

  bool isEnabled;
  Map<String, String> title;
  Map<String, String> subtitle;
  String imageUrl;

  /// Category opened when a user taps the banner. Empty means not tappable.
  String linkCategoryId;
  DateTime updatedAt;

  HomeBannerModel({
    required this.isEnabled,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.linkCategoryId,
    required this.updatedAt,
  });

  factory HomeBannerModel.fromMap(Map<String, dynamic> map) {
    return HomeBannerModel(
      isEnabled: map['isEnabled'] == true,
      title: _parseLocalized(map['title']),
      subtitle: _parseLocalized(map['subtitle']),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      linkCategoryId: (map['linkCategoryId'] ?? '').toString(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is! String
          ? map['updatedAt'].toDate()
          : DateTime.now(),
    );
  }

  factory HomeBannerModel.empty() => HomeBannerModel(
        isEnabled: false,
        title: {},
        subtitle: {},
        imageUrl: '',
        linkCategoryId: '',
        updatedAt: DateTime.now(),
      );

  /// Anything that is not a map is treated as absent rather than throwing on a
  /// hand-edited document.
  static Map<String, String> _parseLocalized(dynamic value) {
    if (value is! Map) return {};
    final result = <String, String>{};
    value.forEach((key, v) {
      if (v != null) result[key.toString()] = v.toString();
    });
    return result;
  }

  /// Blank languages are dropped so the document only carries real content.
  Map<String, dynamic> toMap() => {
        'isEnabled': isEnabled,
        'title': _pruned(title),
        'subtitle': _pruned(subtitle),
        'imageUrl': imageUrl,
        'linkCategoryId': linkCategoryId,
        'updatedAt': updatedAt,
      };

  static Map<String, String> _pruned(Map<String, String> field) => {
        for (final e in field.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      };

  String titleFor(String language) => _localized(title, language);

  String subtitleFor(String language) => _localized(subtitle, language);

  static String _localized(Map<String, String> field, String language) {
    final value = field[language];
    if (value != null && value.trim().isNotEmpty) return value;
    return field[fallbackLanguage]?.trim() ?? '';
  }

  /// How many languages the admin has filled in, for the form's progress hint.
  int get translatedCount => _pruned(title).length;
}
