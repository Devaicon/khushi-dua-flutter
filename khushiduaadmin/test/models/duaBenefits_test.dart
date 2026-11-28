import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/constants/languages.dart';
import 'package:khushiduaadmin/csv/csvSchema.dart';
import 'package:khushiduaadmin/models/duaModel.dart';

void main() {
  group('benefits in 21 languages', () {
    test('English lives in benefits, the rest in benefitsTranslations', () {
      final dua = DuaModel.empty()
        ..setBenefitText('english', ' Protection ')
        ..setBenefitText('urdu', 'حفاظت');
      final map = dua.toMap();
      expect(map['benefits'], 'Protection');
      expect((map['benefitsTranslations'] as Map)['urdu'], 'حفاظت');
      expect(dua.benefitCount, 2);
      expect(kBenefitLanguages.length, 21);
      expect(kBenefitLanguages.map((l) => l.field), contains('arabic'));
    });

    test('every language is written, so a cleared one is blanked on merge',
        () {
      final dua = DuaModel.fromMap({
        'benefits': 'Protection',
        'benefitsTranslations': {'urdu': 'حفاظت', 'hindi': 'सुरक्षा'},
      })
        ..setBenefitText('hindi', '');
      final written = dua.toMap()['benefitsTranslations'] as Map;
      expect(written.length, kBenefitTranslationLanguages.length);
      expect(written['hindi'], '');
      expect(written['urdu'], 'حفاظت');
      expect(written.containsKey('english'), isFalse);
    });

    test('copies are independent', () {
      final dua = DuaModel.fromMap({
        'benefitsTranslations': {'urdu': 'حفاظت'},
      });
      dua.copy().setBenefitText('urdu', 'بدلا');
      expect(dua.benefitText('urdu'), 'حفاظت');
    });

    test('the old list format is read instead of turned into "[{...}]"', () {
      final dua = DuaModel.fromMap({
        'benefits': [
          {'english': 'One', 'urdu': 'ایک', 'gujarati': 'એક'},
          {'english': 'Two', 'mandarin': '二'},
        ],
      });
      expect(dua.benefits, 'One\n\nTwo');
      expect(dua.benefitText('urdu'), 'ایک');
      expect(dua.benefitText('gujrati'), 'એક');
      expect(dua.benefitText('mandrain'), '二');
    });

    test('the duas CSV has a column per translated benefit', () {
      final headers = kCsvSchemas[CsvDataset.duas]!.headers;
      expect(headers, contains('benefits'));
      expect(headers, contains('benefitsTranslations.urdu'));
      expect(headers.where((h) => h.startsWith('benefitsTranslations.')),
          hasLength(20));
      expect(headers, contains('benefitsTranslations.arabic'));
    });
  });
}
