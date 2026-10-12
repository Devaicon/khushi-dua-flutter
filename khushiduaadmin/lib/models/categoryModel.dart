import 'modelValues.dart';
import 'translatedItem.dart';

/// A category on the app's home screen, e.g. "Salah".
class CategoryModel extends TranslatedItem {
  CategoryModel.fromMap(super.map)
      : logo = readString(map['logo']),
        super.fromMap();

  factory CategoryModel.empty() => CategoryModel.fromMap(const {});

  String logo;

  @override
  String get imageUrl => logo;
  @override
  set imageUrl(String value) => logo = value;
  @override
  String get imageField => 'logo';

  CategoryModel copy() => CategoryModel.fromMap(toMap());
}
