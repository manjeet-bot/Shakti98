import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';



class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;



  User? get currentUser => _user ?? _auth.currentUser;

  bool get isAuthenticated => _auth.currentUser != null;

  String get userId => _auth.currentUser?.uid ?? '';

  String get currentUserId => _auth.currentUser?.uid ?? '';

  AuthService() {

    _auth.authStateChanges().listen((User? user) {

      _user = user;

    });

  }



  // Sign up with email and password

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String name, String rank, String coy) async {

    try {

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,

        password: password,

      );



      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'displayName': name,
        'name': name,
        'rank': rank,
        'coy': coy,
        'role': 'member', // Default role
        'createdAt': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'isOnline': true,
        'avatar': '',
      });

      // Also add to members collection
      await _firestore.collection('members').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'displayName': name,
        'name': name,
        'rank': rank,
        'coy': coy,
        'role': 'member',
        'createdAt': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'isOnline': true,
        'avatar': '',
      });



      return result;

    } catch (e) {

      print(e.toString());

      return null;

    }

  }



  // Sign in with email and password

  Future<UserCredential?> signInWithEmailAndPassword(

      String email, String password) async {

    try {

      UserCredential result = await _auth.signInWithEmailAndPassword(

        email: email,

        password: password,

      );



      // Check if user document exists, create if not
      final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!userDoc.exists) {
        // Create user document for existing users
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': result.user!.email,
          'displayName': result.user!.displayName ?? result.user!.email?.split('@')[0] ?? 'User',
          'name': result.user!.displayName ?? result.user!.email?.split('@')[0] ?? 'User',
          'rank': 'AV',
          'role': 'Personnel',
          'coy': 'RHQ',
          'bloodGroup': 'O+',
          'serviceNumber': '',
          'photoUrl': null,
          'profileImageUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
          'chatId': result.user!.uid,
        });
      } else {
        // Update last active for existing users
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      }


      return result;

    } catch (e) {

      print(e.toString());

      return null;

    }

  }



  // Sign in anonymously (for demo)

  Future<void> signInAnonymously() async {

    try {

      if (_auth.currentUser == null) {

        await _auth.signInAnonymously();

        _user = _auth.currentUser;

      }

    } catch (e) {

      throw Exception('Failed to sign in anonymously: $e');

    }

  }



  // Sign out

  Future<void> signOut() async {

    try {

      // Update online status

      if (_auth.currentUser != null) {

        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({

          'isOnline': false,

          'lastActive': Timestamp.now(),

        });

      }

      await _auth.signOut();

      _user = null;

    } catch (e) {

      print(e.toString());

    }

  }



  // Reset password

  Future<void> resetPassword(String email) async {

    try {

      await _auth.sendPasswordResetEmail(email: email);

    } catch (e) {

      print(e.toString());

    }

  }



  // Get user data

  Future<DocumentSnapshot?> getUserData(String uid) async {

    try {

      return await _firestore.collection('users').doc(uid).get();

    } catch (e) {

      print(e.toString());

      return null;

    }

  }



  // Update user profile

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {

    try {

      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));

    } catch (e) {

      print(e.toString());

    }

  }

}

