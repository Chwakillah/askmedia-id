import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType {
  comment,
  reply,
  like,
}

class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final String actorName;
  final String postId;
  final String postTitle;
  final NotificationType type;
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
      'type': type.toString().split('.').last,
      'content': content,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? 'Someone',
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      type: _parseNotificationType(map['type']),
      content: map['content'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).millisecondsSinceEpoch
          : map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'comment':
        return NotificationType.comment;
      case 'reply':
        return NotificationType.reply;
      case 'like':
        return NotificationType.like;
      default:
        return NotificationType.comment;
    }
  }

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} hari lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit lalu";
    } else {
      return "Baru saja";
    }
  }

  String get message {
    switch (type) {
      case NotificationType.comment:
        return "$actorName berkomentar di postingan Anda: \"${_truncateTitle(postTitle)}\"";
      case NotificationType.reply:
        return "$actorName membalas komentar Anda di: \"${_truncateTitle(postTitle)}\"";
      case NotificationType.like:
        return "$actorName menyukai postingan Anda: \"${_truncateTitle(postTitle)}\"";
    }
  }

  String _truncateTitle(String title) {
    return title.length > 30 ? '${title.substring(0, 30)}...' : title;
  }
}

class NotificationController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _collection = 'notifications';

  // Create notification when someone comments on a post
  Future<void> createCommentNotification({
    required String postId,
    required String postTitle,
    required String postAuthorId,
    required String commenterId,
    required String commenterName,
  }) async {
    try {
      // Don't create notification if commenting on own post
      if (postAuthorId == commenterId) return;

      await _firestore.collection(_collection).add({
        'userId': postAuthorId,
        'actorId': commenterId,
        'actorName': commenterName,
        'postId': postId,
        'postTitle': postTitle,
        'type': 'comment',
        'content': '',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Comment notification created for user: $postAuthorId');
    } catch (e) {
      print('Error creating comment notification: $e');
    }
  }

  // Create notification when someone replies to a comment
  Future<void> createReplyNotification({
    required String postId,
    required String postTitle,
    required String originalCommenterId,
    required String replierId,
    required String replierName,
  }) async {
    try {
      // Don't create notification if replying to own comment
      if (originalCommenterId == replierId) return;

      await _firestore.collection(_collection).add({
        'userId': originalCommenterId,
        'actorId': replierId,
        'actorName': replierName,
        'postId': postId,
        'postTitle': postTitle,
        'type': 'reply',
        'content': '',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Reply notification created for user: $originalCommenterId');
    } catch (e) {
      print('Error creating reply notification: $e');
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> streamNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get unread notification count
  Stream<int> streamUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All notifications cleared');
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  // Get notification count for a specific user
  Future<int> getNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }
}