import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/fonts.dart';
import 'package:khushidua/constants/theme.dart';

void main() {
  tearDown(() => Get.locale = null);

  test('Arabic and Urdu get their own fonts, other languages the default',
      () {
    expect(AppFonts.forLanguage('Arabic'), AppFonts.arabic);
    expect(AppFonts.forLanguage('Urdu'), AppFonts.urdu);
    expect(AppFonts.forLanguage('English'), isNull);
    expect(AppFonts.forLanguage('Sindhi'), isNull);
    expect(AppFonts.forLanguage(null), isNull);
  });

  test('line heights are raised only as far as the font needs', () {
    Get.locale = const Locale('Urdu', 'Urdu');
    expect(AppFonts.height(1.4), AppFonts.urduMinHeight);
    expect(AppFonts.height(2.4), 2.4);
    expect(AppFonts.height(null), AppFonts.urduMinHeight);

    Get.locale = const Locale('Arabic', 'Arabic');
    expect(AppFonts.height(1.5), AppFonts.arabicMinHeight);

    Get.locale = const Locale('English', 'English');
    expect(AppFonts.height(1.4), 1.4);
    expect(AppFonts.height(null), isNull);

    expect(AppFonts.height(1.4, family: AppFonts.arabic),
        AppFonts.arabicMinHeight);
  });

  test('the theme follows the app language', () {
    Get.locale = const Locale('English', 'English');
    final english = buildAppTheme();
    expect(english.textTheme.bodyMedium!.fontFamily, isNot(AppFonts.urdu));
    expect(english.textTheme.bodyMedium!.fontFamilyFallback,
        contains(AppFonts.naskh));

    Get.locale = const Locale('Urdu', 'Urdu');
    final urdu = buildAppTheme();
    for (final style in [
      urdu.textTheme.bodyMedium!,
      urdu.textTheme.titleLarge!,
      urdu.textTheme.labelLarge!,
      urdu.appBarTheme.titleTextStyle!,
      urdu.dialogTheme.contentTextStyle!,
    ]) {
      expect(style.fontFamily, AppFonts.urdu);
      expect(style.fontFamilyFallback, contains(AppFonts.naskh));
    }
    expect(urdu.textTheme.bodyMedium!.height,
        greaterThanOrEqualTo(AppFonts.urduMinHeight));

    Get.locale = const Locale('Arabic', 'Arabic');
    final arabic = buildAppTheme();
    expect(arabic.textTheme.bodyMedium!.fontFamily, AppFonts.arabic);
    expect(arabic.textTheme.bodyMedium!.height,
        greaterThanOrEqualTo(AppFonts.arabicMinHeight));
  });

  testWidgets('switching language re-themes the running app', (tester) async {
    await tester.pumpWidget(const _App());
    final text = find.text('x');
    TextStyle style() => DefaultTextStyle.of(tester.element(text)).style;
    expect(style().fontFamily, isNot(AppFonts.urdu));

    // What UserController.setSelectedLanguage does. updateLocale waits for
    // the rebuild's frame, so start it and pump rather than await it first.
    final update = Get.updateLocale(const Locale('Urdu', 'Urdu'));
    await tester.pumpAndSettle();
    await update;
    expect(style().fontFamily, AppFonts.urdu);
  });
}

/// Mirrors main.dart: the theme is built in build(), which Get.updateLocale
/// runs again.
class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        locale: const Locale('English', 'English'),
        theme: buildAppTheme(),
        home: const Scaffold(body: Text('x')),
      );
}
