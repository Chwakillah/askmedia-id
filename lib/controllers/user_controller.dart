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
      print("User berhasil disimpan ke Firestore: ${user.id}");
    } catch (e) {
      print("Error saving user to Firestore: $e");
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No current user found");
        return null;
      }

      print("Getting current user data for UID: ${currentUser.uid}");
      final doc = await _firestore.collection(_userCollection).doc(currentUser.uid).get();
      
      if (!doc.exists) {
        print("User document does not exist in Firestore");
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print("User document data is null");
        return null;
      }

      print("User data retrieved successfully");
      return UserModel.fromMap(data);
    } catch (e) {
      print("Error getting current user: $e");
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
      print("Error getting user by ID: $e");
      return null;
    }
  }

  Future<bool> updateUserProfile(String name, String bio) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No current user for update");
        return false;
      }

      print("Updating profile for UID: ${currentUser.uid}");
      print("New name: $name");
      print("New bio: $bio");

      final docRef = _firestore.collection(_userCollection).doc(currentUser.uid);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        print("User document does not exist, cannot update");
        return false;
      }

      await docRef.update({
        'name': name,
        'bio': bio,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      print("Profile updated successfully");
      return true;
    } catch (e) {
      print("Error updating user profile: $e");
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