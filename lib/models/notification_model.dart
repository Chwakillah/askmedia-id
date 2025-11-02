import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId; 
  final String actorId; 
  final String actorName;
  final String postId;
  final String postTitle;
  final String type; 
  final String content;
  final bool isRead;
  final int timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    required this.postId,
    required this.postTitle,
    required this.type,
    required this.content,
    required this.isRead,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'actorId': actorId,
      'actorName': actorName,
      'postId': postId,
      'postTitle': postTitle,
      'type': type,
      'content': content,
      'isRead': isRead,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    final rawTs = map['timestamp'];
    int ts;
    if (rawTs is Timestamp) {
      ts = rawTs.millisecondsSinceEpoch;
    } else if (rawTs is int) {
      ts = rawTs;
    } else {
      ts = DateTime.now().millisecondsSinceEpoch;
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      type: map['type'] ?? 'comment',
      content: map['content'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: ts,
    );
  }

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }
}
