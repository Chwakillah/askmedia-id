// controllers/post_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all posts
  Future<List<PostModel>> fetchPosts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  // Fetch post by ID - UNTUK NOTIFIKASI
  Future<PostModel?> fetchPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      
      if (doc.exists) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching post by ID: $e');
      rethrow;
    }
  }

  // Create a new post
  Future<bool> createPost(PostModel post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  // Update an existing post - SUPPORT BOTH SIGNATURES
  Future<bool> updatePost(dynamic postIdOrModel, [String? title, String? content]) async {
    try {
      // Jika parameter pertama adalah String (postId) dan ada title & content
      if (postIdOrModel is String && title != null && content != null) {
        // Signature lama dari EditPostView: updatePost(postId, title, content)
        final updateData = {
          'title': title,
          'content': content,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await _firestore.collection('posts').doc(postIdOrModel).update(updateData);
        return true;
      }
      
      // Jika parameter pertama adalah PostModel
      if (postIdOrModel is PostModel) {
        // Signature baru: updatePost(PostModel)
        await _firestore
            .collection('posts')
            .doc(postIdOrModel.id)
            .update(postIdOrModel.toMap());
        return true;
      }

      // Jika signature lain (untuk backward compatibility)
      if (postIdOrModel is String && title == null && content == null) {
        // Anggap ini adalah call dengan PostModel yang di-pass sebagai postId
        return false;
      }

      return false;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      // Delete post document
      await _firestore.collection('posts').doc(postId).delete();
      
      // Delete associated comments
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete associated notifications
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete associated bookmarks
      final bookmarksSnapshot = await _firestore
          .collection('bookmarks')
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var doc in bookmarksSnapshot.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Get current user's posts
  Future<List<PostModel>> fetchUserPosts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching user posts: $e');
      rethrow;
    }
  }

  // Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      final posts = snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Filter posts by query
      return posts.where((post) {
        final searchQuery = query.toLowerCase();
        return post.title.toLowerCase().contains(searchQuery) ||
               post.content.toLowerCase().contains(searchQuery) ||
               post.authorName.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching posts: $e');
      rethrow;
    }
  }
}