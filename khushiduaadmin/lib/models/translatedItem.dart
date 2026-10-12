import '../constants/languages.dart';
import 'modelValues.dart';

/// What categories and sections (subcategories) share: a name in every
/// language, an image, age groups, an on/off switch and a position.
///
/// Lets one editor and one list serve both.
abstract class TranslatedItem {
  TranslatedItem.fromMap(Map<String, dynamic> map)
      : id = readString(map['id']),
        names = {
          for (final l in kContentLanguages) l.field: readString(map[l.field]),
        },
        isEnabled = readBool(map['isEnabled']),
        order = readInt(map['order']),
        littleKids = readBool(map['littleKids']),
        olderKids = readBool(map['olderKids']),
        grownUps = readBool(map['grownUps']),
        createdAt = readDate(map['createdAt']),
        updatedAt = readDate(map['updatedAt']);

  String id;

  /// Name by language field (see [kContentLanguages]).
  final Map<String, String> names;

  bool isEnabled;
  int order;
  bool littleKids;
  bool olderKids;
  bool grownUps;
  DateTime createdAt;
  DateTime updatedAt;

  /// The logo of a category, or the illustration of a section.
  String get imageUrl;
  set imageUrl(String value);

  /// The Firestore field [imageUrl] is stored under.
  String get imageField;

  String get english => names['english'] ?? '';
  String get arabic => names['arabic'] ?? '';
  String get urdu => names['urdu'] ?? '';

  /// A one-line name for lists.
  String get title => english.trim().isNotEmpty
      ? english.trim()
      : (arabic.trim().isNotEmpty ? arabic.trim() : '(untitled)');

  String text(String field) => names[field] ?? '';
  void setText(String field, String value) => names[field] = value;

  bool shownTo(AgeGroup group) => switch (group) {
        AgeGroup.littleKids => littleKids,
        AgeGroup.olderKids => olderKids,
        AgeGroup.grownUps => grownUps,
      };

  void setShownTo(AgeGroup group, bool shown) {
    switch (group) {
      case AgeGroup.littleKids:
        littleKids = shown;
      case AgeGroup.olderKids:
        olderKids = shown;
      case AgeGroup.grownUps:
        grownUps = shown;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        ...names,
        imageField: imageUrl,
        'isEnabled': isEnabled,
        'order': order,
        'littleKids': littleKids,
        'olderKids': olderKids,
        'grownUps': grownUps,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
