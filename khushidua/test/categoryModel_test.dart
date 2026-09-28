import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/models/categoryModel.dart';

/// Category names come from Firestore, one field per language. Admins do not
/// always fill every field, and an empty field used to render a blank tile.
CategoryModel _category({String english = '', String urdu = '', String hindi = ''}) {
  return CategoryModel(
    id: 'c1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    arabic: '', bengali: '', english: english, french: '', german: '',
    gujrati: '', hindi: hindi, indonesian: '', isEnabled: true, japanese: '',
    logo: '', malay: '', mandrain: '', marathi: '', portugese: '', punjabi: '',
    russian: '', sindhi: '', spanish: '', tamil: '', telgu: '', turkish: '',
    urdu: urdu, order: 0, grownUps: true, littleKids: true, olderKids: true,
  );
}

void main() {
  test('uses the selected language when it is filled in', () {
    final category = _category(english: 'Protection', urdu: 'حفاظت');
    expect(category.getName('Urdu'), 'حفاظت');
  });

  test('falls back to English when the language field is empty', () {
    final category = _category(english: 'Protection');
    expect(category.getName('Hindi'), 'Protection');
  });

  test('falls back to any filled field when English is empty too', () {
    final category = _category(hindi: 'सुरक्षा');
    expect(category.getName('Urdu'), 'सुरक्षा');
  });

  test('returns empty only when every field is empty', () {
    expect(_category().getName('Urdu'), '');
  });

  test('an unknown language code still resolves to English', () {
    final category = _category(english: 'Protection');
    expect(category.getName('Klingon'), 'Protection');
  });
}
