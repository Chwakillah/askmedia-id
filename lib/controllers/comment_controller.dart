import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentController {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addComment(String postId, CommentModel comment) async {
    await _firestore.collection('posts').doc(postId).collection('comments').add(comment.toMap());
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final snapshot = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
  }
}
