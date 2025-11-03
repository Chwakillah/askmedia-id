import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventBookmarkController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<bool> toggleBookmark(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final bookmarkRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_bookmarks')
          .doc(eventId);

      final doc = await bookmarkRef.get();

      if (doc.exists) {
        // Remove bookmark
        await bookmarkRef.delete();
        return false;
      } else {
        // Add bookmark
        await bookmarkRef.set({
          'eventId': eventId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBookmarked(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_bookmarks')
          .doc(eventId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking event bookmark: $e');
      return false;
    }
  }

  Future<List<String>> getBookmarkedEventIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_bookmarks')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<String>> streamBookmarkedEventIds() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('event_bookmarks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<int> getBookmarkCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_bookmarks')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting event bookmark count: $e');
      return 0;
    }
  }

  Future<void> clearAllBookmarks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_bookmarks')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All event bookmarks cleared');
    } catch (e) {
      print('Error clearing event bookmarks: $e');
    }
  }
}