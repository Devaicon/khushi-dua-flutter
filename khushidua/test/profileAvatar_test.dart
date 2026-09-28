import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/widgets/profileAvatar.dart';

void main() {
  test('the girl avatar is recognised', () {
    expect(isGirlAvatar('assets/images/female.png'), isTrue);
  });

  test('the boy avatar is not mistaken for the girl', () {
    expect(isGirlAvatar('assets/images/male.png'), isFalse);
  });

  test('"female" containing "male" no longer matters', () {
    // The old check was path.contains("male"), true for both files.
    const paths = ['assets/images/male.png', 'assets/images/female.png'];
    expect(paths.where(isGirlAvatar), hasLength(1));
  });
}
