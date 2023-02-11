library servicekit;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
export 'errors.dart';

abstract class ServiceKit {
  final _authRef = FirebaseAuth.instance;

  Future<void> refreshUser() async {
    await _authRef.currentUser?.reload();
    // user.trigger(_authRef.currentUser);
  }

  DocumentReference _userDocRef({String? uid}) {
    return FirebaseFirestore.instance.collection("users").doc(uid);
  }

  Future<void> logout() async {
    return _authRef.signOut();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required Object? userDocumentData,
  }) async {
    var credential = await _authRef.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    credential.user!.sendEmailVerification();
    credential.user!.updateDisplayName(displayName);

    _userDocRef(uid: credential.user!.uid).set(userDocumentData);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _authRef.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
