import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _userCollection = 'users';

  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await _firestore.collection(_userCollection).doc(user.id).set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final doc = await _firestore.collection(_userCollection).doc(currentUser.uid).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return UserModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_userCollection).doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return UserModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile(String name, String bio) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final docRef = _firestore.collection(_userCollection).doc(currentUser.uid);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        return false;
      }

      await docRef.update({
        'name': name,
        'bio': bio,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ensureUserDocument(User firebaseUser) async {
    try {
      final docRef = _firestore.collection(_userCollection).doc(firebaseUser.uid);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        final newUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          bio: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        
        await docRef.set(newUser.toMap());
        print("Created new user document for UID: ${firebaseUser.uid}");
        return true;
      }
      
      return true;
    } catch (e) {
      print("Error ensuring user document: $e");
      return false;
    }
  }
}