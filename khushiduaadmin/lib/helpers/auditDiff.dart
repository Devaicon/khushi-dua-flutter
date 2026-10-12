/// Which fields an edit changed, for the change history.
///
/// Pure Dart, so it can be unit tested.
library;

/// Bookkeeping fields every save rewrites; listing them would hide the
/// change that matters.
const Set<String> kIgnoredDiffFields = {'updatedAt', 'createdAt', 'id'};

/// The fields whose values differ between [before] and [after], sorted.
/// A field missing on one side counts as changed only if the other side has
/// something in it (so `null`, `""` and missing all read as empty).
List<String> changedFields(
  Map<String, dynamic>? before,
  Map<String, dynamic>? after,
) {
  final keys = {...?before?.keys, ...?after?.keys}
    ..removeAll(kIgnoredDiffFields);
  return [
    for (final key in keys)
      if (!_sameValue(before?[key], after?[key])) key,
  ]..sort();
}

bool _isEmpty(Object? v) =>
    v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty);

bool _sameValue(Object? a, Object? b) {
  if (_isEmpty(a) && _isEmpty(b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameValue(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_sameValue(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}

/// "English, Urdu and 3 more".
String describeFields(List<String> fields, {int show = 3}) {
  if (fields.isEmpty) return 'no visible changes';
  final labels = fields.map(fieldLabel).toList();
  if (labels.length <= show) {
    if (labels.length == 1) return labels.first;
    return '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
  }
  return '${labels.take(show).join(', ')} and ${labels.length - show} more';
}

/// A readable name for a Firestore field.
String fieldLabel(String field) => switch (field) {
      'littleKidsAudio' => 'Little Kids audio',
      'olderKidsAudio' => 'Older Kids audio',
      'grownUpsAudio' => 'Grown-ups audio',
      'englishTranslation' => 'English audio',
      'urduTranslation' => 'Urdu audio',
      'subCategoryIds' => 'Sections',
      'isEnabled' => 'Visibility',
      'littleKids' => 'Little Kids',
      'olderKids' => 'Older Kids',
      'grownUps' => 'Grown-ups',
      'gujrati' => 'Gujarati',
      'mandrain' => 'Mandarin',
      'portugese' => 'Portuguese',
      'telgu' => 'Telugu',
      'categoryId' => 'Category',
      'isMember' => 'Membership',
      'isBlocked' => 'Blocked',
      _ => field.isEmpty
          ? field
          : '${field[0].toUpperCase()}${field.substring(1)}',
    };
