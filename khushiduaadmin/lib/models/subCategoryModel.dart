import 'modelValues.dart';
import 'translatedItem.dart';

/// A section of a category, e.g. "Before Salah". The app calls these
/// sections; Firestore calls them subcategories.
class SubCategoryModel extends TranslatedItem {
  SubCategoryModel.fromMap(super.map)
      : categoryId = readString(map['categoryId']),
        image = readString(map['image']),
        super.fromMap();

  factory SubCategoryModel.empty(String categoryId) =>
      SubCategoryModel.fromMap({'categoryId': categoryId});

  String categoryId;

  /// The illustration shown above the duas for kids. Optional.
  String image;

  @override
  String get imageUrl => image;
  @override
  set imageUrl(String value) => image = value;
  @override
  String get imageField => 'image';

  @override
  Map<String, dynamic> toMap() => {...super.toMap(), 'categoryId': categoryId};

  SubCategoryModel copy() => SubCategoryModel.fromMap(toMap());
}
