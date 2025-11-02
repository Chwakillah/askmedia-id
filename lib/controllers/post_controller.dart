import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostController {
  final _firestore = FirebaseFirestore.instance;
  final _collection = 'posts';

  Future<List<PostModel>> fetchPosts() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return PostModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<void> createPost(PostModel post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    final userData = userDoc.data();
    final userName = userData?['name'] ?? currentUser.displayName ?? 'Pengguna';

    await _firestore.collection(_collection).add({
      'userId': currentUser.uid,
      'authorEmail': currentUser.email ?? '',
      'authorName': userName,
      'title': post.title,
      'content': post.content,
      'timestamp': post.timestamp,
    });
  }

  Future<bool> updatePost(String id, String title, String content) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'title': title,
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePost(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}