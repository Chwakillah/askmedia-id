import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Toggle bookmark status
  Future<bool> toggleBookmark(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final bookmarkRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(postId);

      final doc = await bookmarkRef.get();

      if (doc.exists) {
        // Remove bookmark
        await bookmarkRef.delete();
        return false;
      } else {
        // Add bookmark
        await bookmarkRef.set({
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  // Check if post is bookmarked
  Future<bool> isBookmarked(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(postId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all bookmarked post IDs
  Future<List<String>> getBookmarkedPostIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Stream of bookmarked post IDs
  Stream<List<String>> streamBookmarkedPostIds() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Get bookmark count for a user
  Future<int> getBookmarkCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Remove all bookmarks
  Future<void> clearAllBookmarks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
    }
  }
}