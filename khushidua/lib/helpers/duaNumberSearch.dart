/// A search for a dua by its number within a section: "3", "#3", "dua 3",
/// "morning 3" or "3 morning". The number is the one shown on each dua
/// ("Dua 3 of 7").
class DuaNumberQuery {
  const DuaNumberQuery({required this.number, required this.text});

  /// The dua's position in its section, from 1.
  final int number;

  /// What is left to match against section and category names; empty when
  /// the query was only a number.
  final String text;

  static final _number = RegExp(r'^#?(\d{1,4})$');

  /// Words that only say "dua", dropped when a number is present so "dua 3"
  /// means the same as "3".
  static const _filler = {'dua', 'duas', 'no', 'no.', 'number', '#'};

  /// Null when the query holds no number, or nothing but filler words.
  static DuaNumberQuery? parse(String query) {
    final words = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    // The last number is the dua, so "99 names 2" looks for the second dua
    // of "99 names"; any earlier number stays in the name.
    final at = words.lastIndexWhere(_number.hasMatch);
    if (at < 0) return null;
    final number = int.parse(_number.firstMatch(words[at])!.group(1)!);
    final rest = [...words.take(at), ...words.skip(at + 1)];
    if (number < 1) return null;
    return DuaNumberQuery(
      number: number,
      text: rest.where((w) => !_filler.contains(w)).join(' '),
    );
  }
}
