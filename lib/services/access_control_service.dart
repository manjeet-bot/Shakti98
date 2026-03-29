import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessControlService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is allowed to access the app
  static Future<bool> isUserAllowed(String email) async {
    try {
      // Check if user exists in allowed_users collection
      final doc = await _firestore.collection('allowed_users').doc(email).get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        return userData['allowed'] == true;
      }
      
      return false; // Default: not allowed
    } catch (e) {
      print('Error checking user access: $e');
      return false;
    }
  }

  // Add user to allowed list (for admin)
  static Future<void> addAllowedUser(String email, {String? addedBy}) async {
    try {
      await _firestore.collection('allowed_users').doc(email).set({
        'email': email,
        'allowed': true,
        'addedAt': Timestamp.now(),
        'addedBy': addedBy ?? 'system',
        'status': 'active',
      });
    } catch (e) {
      print('Error adding allowed user: $e');
      throw e;
    }
  }

  // Remove user from allowed list
  static Future<void> removeAllowedUser(String email) async {
    try {
      await _firestore.collection('allowed_users').doc(email).update({
        'allowed': false,
        'status': 'inactive',
        'removedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error removing allowed user: $e');
      throw e;
    }
  }

  // Get all allowed users (for admin)
  static Future<List<Map<String, dynamic>>> getAllowedUsers() async {
    try {
      final snapshot = await _firestore
          .collection('allowed_users')
          .where('allowed', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting allowed users: $e');
      return [];
    }
  }

  // Auto-add user when they signup (if they have access code)
  static Future<bool> validateAccessCode(String code) async {
    try {
      final doc = await _firestore.collection('access_codes').doc(code).get();
      
      if (doc.exists) {
        final codeData = doc.data() as Map<String, dynamic>;
        if (codeData['valid'] == true && codeData['uses'] < codeData['maxUses']) {
          // Increment usage
          await _firestore.collection('access_codes').doc(code).update({
            'uses': FieldValue.increment(1),
          });
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error validating access code: $e');
      return false;
    }
  }
}
