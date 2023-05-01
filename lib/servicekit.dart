library servicekit;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference, FirebaseFirestore;

class ServiceKit {
  FirebaseAuth get _inst => FirebaseAuth.instance;
  User? get currentUser => _inst.currentUser;
  String? get uid => currentUser?.uid;

  Stream<User?> get authStateChanges => _inst.authStateChanges();

  DocumentReference<Map<String, dynamic>> get userDoc => FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> loginPhone({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 30),
    required void Function(String verificationId, Duration timeout) codeSent,
  }) async {}

  void enterVerificationCode({
    required String smsCode,
    required String verificationId,
    Map<String, dynamic>? userDocumentMap,
    required void Function(String errorMessage) onError,
  }) {}

  Future<void> logout() async {
    await _inst.signOut();
  }

  Future<bool> deleteAccount() async {
    await userDoc.delete();
    await currentUser!.delete();
    return true;
  }
}
