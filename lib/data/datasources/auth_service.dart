import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Sync user data to Firestore
      if (userCredential.user != null) {
        await _syncUserData(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // Sync user data to Firestore
  Future<void> _syncUserData(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      // Create new user document
      await userDoc.set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'planCount': 0,
        'isPremium': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Update last login
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
