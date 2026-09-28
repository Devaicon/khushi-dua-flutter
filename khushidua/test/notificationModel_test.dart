import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/models/notificationModel.dart';

void main() {
  test('reads a fully written notification', () {
    final created = DateTime(2026, 9, 16, 9);
    final n = NotificationModel.fromMap({
      'id': 'n1',
      'title': 'Eid Mubarak',
      'message': 'Hello',
      'createdAt': Timestamp.fromDate(created),
      'sentTo': 'u1',
    });
    expect(n.id, 'n1');
    expect(n.title, 'Eid Mubarak');
    expect(n.createdAt, created);
    expect(n.sentTo, 'u1');
  });

  test('tolerates a server timestamp that has not resolved yet', () {
    // The Cloud Function writes createdAt with serverTimestamp(); a listener
    // can see the document before the value exists. This used to throw.
    final n = NotificationModel.fromMap({
      'id': 'n2',
      'title': 'T',
      'message': 'M',
      'createdAt': null,
      'sentTo': null,
    });
    expect(n.createdAt, isNotNull);
    expect(n.sentTo, isNull);
  });

  test('falls back to the document id and empty text', () {
    final n = NotificationModel.fromMap({}, docId: 'doc-7');
    expect(n.id, 'doc-7');
    expect(n.title, '');
    expect(n.message, '');
  });
}
