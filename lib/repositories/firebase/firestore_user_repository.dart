import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_role.dart';
import '../user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<UserRole?> getUserRole(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserRole.fromString(doc.data()?['role'] as String?);
  }

  @override
  Future<String?> findEmailByPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    final snapshot = await _users
        .where('phone', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['email'] as String?;
  }

  @override
  Future<bool> accountExistsByEmail(String email) async {
    final snapshot = await _users
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? phone,
    UserRole role = UserRole.customer,
    String? displayName,
  }) async {
    await _users.doc(uid).set({
      'email': email.trim().toLowerCase(),
      if (phone != null && phone.isNotEmpty)
        'phone': phone.replaceAll(RegExp(r'[\s\-()]'), ''),
      'role': role.firestoreValue,
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
