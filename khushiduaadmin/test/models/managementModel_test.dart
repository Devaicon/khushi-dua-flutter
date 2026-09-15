import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/models/managementModel.dart';

void main() {
  test('reads Firestore timestamps', () {
    final at = DateTime.utc(2026, 9, 14, 10);
    final model = ManagementModel.fromMap({
      'id': 'u1',
      'email': 'ops@company.com',
      'firstName': 'Sara',
      'lastName': 'Khan',
      'role': 'Super_Admin',
      'createdAt': Timestamp.fromDate(at),
      'updatedAt': Timestamp.fromDate(at),
    });
    expect(model.createdAt.toUtc(), at);
    expect(model.isSuperAdmin, isTrue);
  });

  test('tolerates a document typed by hand in the Firebase Console', () {
    final model = ManagementModel.fromMap({
      'id': 'u1',
      'email': 'ops@company.com',
      'role': 'Super_Admin',
      'createdAt': '2026-09-14T10:00:00Z',
    });
    expect(model.firstName, '');
    expect(model.createdAt, DateTime.utc(2026, 9, 14, 10));
    expect(model.updatedAt, isA<DateTime>());
  });

  test('a missing role defaults to Admin, never Super_Admin', () {
    final model = ManagementModel.fromMap({'id': 'u1', 'email': 'a@b.co'});
    expect(model.role, 'Admin');
    expect(model.isSuperAdmin, isFalse);
  });

  test('empty() is a blank, non-super admin', () {
    final model = ManagementModel.empty();
    expect(model.id, '');
    expect(model.isSuperAdmin, isFalse);
  });
}
