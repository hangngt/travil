import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travil/data/services/firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  User? get user => _user;

  /// listen login state
  Stream<User?> authStateChange() => _auth.authStateChanges();

  AuthService() {
    _auth.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  /// Anonymous login
  Future<User?> signInAnon() async {
    final result = await _auth.signInAnonymously();

    _user = result.user;

    if (_user != null) {
      await _firestore.logActivity(_user!.uid, "anonymous_login");
    }

    notifyListeners();
    return _user;
  }

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Register
  Future<void> register(String name, String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await result.user?.updateDisplayName(name);
    _user = result.user;
    if (_user != null) {
      // chạy song song
      _firestore.saveUser(_user!.uid, name, email);
      _firestore.logActivity(_user!.uid, "register");
      _saveToken();
    }

    notifyListeners();
  }

  /// Login
  Future<void> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    _user = result.user;

    if (_user != null) {
      await _firestore.logActivity(_user!.uid, "login");

      await _saveToken();
    }

    notifyListeners();
  }

  /// Logout

  Future<void> logout() async {
    try {
      if (_user != null) {
        await _firestore.logActivity(_user!.uid, "logout");
      }

      // logout google
      await _googleSignIn.signOut();

      // logout firebase
      await _auth.signOut();

      _user = null;

      notifyListeners();

      print("LOGOUT SUCCESS");
    } catch (e) {
      print("LOGOUT ERROR: $e");
    }
  }

  /// Save device token
  Future<void> _saveToken() async {
    Future.delayed(Duration(seconds: 2), () async {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || _user == null) return;

      await FirebaseFirestore.instance.collection("users").doc(_user!.uid).set({
        "deviceToken": token,
      }, SetOptions(merge: true));
    });
  }

  Future<User?> signInWithGoogle() async {
    try {
      print("START GOOGLE LOGIN");

      // clear old session
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      print("USER: $googleUser");

      if (googleUser == null) {
        print("LOGIN CANCELLED");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      _user = result.user;

      print("LOGIN SUCCESS");

      notifyListeners();

      return result.user;
    } catch (e, s) {
      print("ERROR: $e");
      print("STACK: $s");

      return null;
    }
  }
}
