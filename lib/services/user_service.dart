import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user profile image URL
  static Future<String?> getUserProfileImage(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['profileImageUrl'];
      }
      return null;
    } catch (e) {
      print('Error getting user profile image: $e');
      return null;
    }
  }

  // Get current user profile image URL
  static Future<String?> getCurrentUserProfileImage() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await getUserProfileImage(user.uid);
    }
    return null;
  }

  // Get user display name
  static Future<String> getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['displayName'] ?? data['email'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Unknown User';
    }
  }
}
