import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  //  STABLE CONFIG (không dùng v7 API mới unstable)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  User? _user;
  User? get user => _user;

  // AuthService() {
  //   _auth.authStateChanges().listen((User? u) {
  //     _user = u;
  //     notifyListeners();
  //   });
  // }
  AuthService() {
    Future.microtask(() {
      _auth.authStateChanges().listen((User? u) {
        _user = u;
        notifyListeners();
      });
    });
  }

  // EMAIL / PASSWORD

  Future<void> register(String name, String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await result.user?.updateDisplayName(name);

    _user = result.user;

    if (_user != null) {
      await _firestore.createUserIfNotExists(_user!.uid, name, email);
      await _firestore.logActivity(_user!.uid, "register");
      await _saveDeviceToken();
    }

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    _user = result.user;

    if (_user != null) {
      await _firestore.logActivity(_user!.uid, "login");
      await _saveDeviceToken();
    }

    notifyListeners();
  }

  // GOOGLE SIGN-IN

  Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      //  SAFE SIGN-IN (không dùng authenticate() v7)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      //  accessToken có thể null → vẫn an toàn
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      _user = userCredential.user;

      if (_user != null) {
        await _firestore.createUserIfNotExists(
          _user!.uid,
          _user!.displayName ?? "Google User",
          _user!.email ?? "",
        );

        await _firestore.logActivity(_user!.uid, "google_login");
        await _saveDeviceToken();
      }

      notifyListeners();
      return _user;
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }

  // ANONYMOUS

  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    _user = result.user;

    if (_user != null) {
      await _firestore.createUserIfNotExists(
        _user!.uid,
        "Anonymous",
        "",
      );
      await _firestore.logActivity(_user!.uid, "anonymous_login");
    }

    notifyListeners();
    return _user;
  }

  // LOGOUT

  Future<void> logout() async {
    try {
      if (_user != null) {
        await _firestore.logActivity(_user!.uid, "logout");
      }

      await _googleSignIn.signOut();
      await _auth.signOut();

      _user = null;
      notifyListeners();
    } catch (e) {
      print("Logout error: $e");
    }
  }

  // DEVICE TOKEN

  Future<void> _saveDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || _user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
      'deviceToken': token,
    }, SetOptions(merge: true));
  }
}
