import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String kind;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestampVal = data['created_at'];
    DateTime parsedTime = DateTime.now();
    if (timestampVal is Timestamp) {
      parsedTime = timestampVal.toDate();
    }
    return AppNotification(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      kind: data['kind'] ?? 'store',
      createdAt: parsedTime,
      read: data['read'] as bool? ?? false,
    );
  }
}
