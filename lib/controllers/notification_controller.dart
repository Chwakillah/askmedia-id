// controllers/notification_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Buat notifikasi ketika ada komentar baru di postingan user
  Future<void> createCommentNotification({
    required String postId,
    required String postTitle,
    required String postAuthorId,
    required String commenterId,
    required String commenterName,
  }) async {
    try {
      // Jangan kirim notif ke diri sendiri
      if (postAuthorId == commenterId) return;

      final notification = NotificationModel(
        id: '',
        userId: postAuthorId,
        type: 'comment',
        postId: postId,
        postTitle: postTitle,
        actorId: commenterId,
        actorName: commenterName,
        message: '$commenterName berkomentar di postingan Anda',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isRead: false,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toMap());
    } catch (e) {
      print('Error creating comment notification: $e');
      rethrow;
    }
  }

  // Buat notifikasi untuk user yang bookmark postingan ketika ada komentar baru
  Future<void> createBookmarkCommentNotification({
    required String postId,
    required String postTitle,
    required String commenterId,
    required String commenterName,
  }) async {
    try {
      // Ambil semua user yang bookmark postingan ini
      final bookmarksSnapshot = await _firestore
          .collection('bookmarks')
          .where('postId', isEqualTo: postId)
          .get();

      for (var doc in bookmarksSnapshot.docs) {
        final userId = doc.data()['userId'] as String;
        
        // Jangan kirim notif ke komentator sendiri
        if (userId == commenterId) continue;

        final notification = NotificationModel(
          id: '',
          userId: userId,
          type: 'bookmark_comment',
          postId: postId,
          postTitle: postTitle,
          actorId: commenterId,
          actorName: commenterName,
          message: '$commenterName berkomentar di postingan yang Anda simpan',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isRead: false,
        );

        await _firestore
            .collection('notifications')
            .add(notification.toMap());
      }
    } catch (e) {
      print('Error creating bookmark comment notification: $e');
    }
  }

  // Stream notifikasi user saat ini
  Stream<List<NotificationModel>> streamNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Stream jumlah notifikasi yang belum dibaca
  Stream<int> streamUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Tandai notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Tandai semua notifikasi sebagai sudah dibaca
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }

  // Hapus notifikasi
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Hapus semua notifikasi user
  Future<void> deleteAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }
}