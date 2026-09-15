import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/csv/firestoreValues.dart';

void main() {
  test('converts timestamps to UTC DateTimes at any depth', () {
    final at = DateTime.utc(2026, 9, 14, 10);
    final result = normalizeFirestoreValue({
      'createdAt': Timestamp.fromDate(at),
      'nested': {'when': Timestamp.fromDate(at)},
      'list': [Timestamp.fromDate(at), 'text'],
      'plain': 3,
    }) as Map<String, dynamic>;

    expect(result['createdAt'], at);
    expect((result['nested'] as Map)['when'], at);
    expect(result['list'], [at, 'text']);
    expect(result['plain'], 3);
  });
}
