/// The home screen banner, authored in the admin panel and stored at
/// `SystemConfiguration/HomeBanner`.
///
/// `title` and `subtitle` are per-language maps keyed by the same language
/// names the app uses for `selectedLanguage` ("English", "Arabic", …), so the
/// banner follows the user's language the way dua and category names do.
class HomeBannerModel {
  static const String docId = 'HomeBanner';
  static const String fallbackLanguage = 'English';

  final bool isEnabled;
  final Map<String, String> title;
  final Map<String, String> subtitle;
  final String imageUrl;

  /// Category opened when the banner is tapped. Empty means not tappable.
  final String linkCategoryId;

  const HomeBannerModel({
    required this.isEnabled,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.linkCategoryId,
  });

  factory HomeBannerModel.fromMap(Map<String, dynamic> map) {
    return HomeBannerModel(
      isEnabled: map['isEnabled'] == true,
      title: _parseLocalized(map['title']),
      subtitle: _parseLocalized(map['subtitle']),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      linkCategoryId: (map['linkCategoryId'] ?? '').toString(),
    );
  }

  /// An empty, disabled banner — used before the document loads and when it
  /// does not exist, so the home screen always has something to render from.
  factory HomeBannerModel.empty() => const HomeBannerModel(
    isEnabled: false,
    title: {},
    subtitle: {},
    imageUrl: '',
    linkCategoryId: '',
  );

  /// Anything that is not a map of strings is treated as absent rather than
  /// crashing the home screen on a malformed document.
  static Map<String, String> _parseLocalized(dynamic value) {
    if (value is! Map) return {};
    final result = <String, String>{};
    value.forEach((key, v) {
      if (v != null) result[key.toString()] = v.toString();
    });
    return result;
  }

  Map<String, dynamic> toMap() => {
    'isEnabled': isEnabled,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'linkCategoryId': linkCategoryId,
  };

  String titleFor(String language) => _localized(title, language);

  String subtitleFor(String language) => _localized(subtitle, language);

  /// Falls back to English when the language is missing or blank, so a banner
  /// the admin has only written in English still reaches every user.
  static String _localized(Map<String, String> field, String language) {
    final value = field[language];
    if (value != null && value.trim().isNotEmpty) return value;
    return field[fallbackLanguage]?.trim() ?? '';
  }

  bool get hasLink => linkCategoryId.isNotEmpty;

  bool get hasImage => imageUrl.isNotEmpty;

  /// Whether there is anything worth showing for this language.
  bool hasContent(String language) {
    if (!isEnabled) return false;
    return titleFor(language).isNotEmpty || subtitleFor(language).isNotEmpty;
  }
}
