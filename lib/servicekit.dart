library servicekit;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'errors.dart';

abstract class ServiceKit {
  FirebaseAuth get _inst => FirebaseAuth.instance;

  User? get currentUser => _inst.currentUser;

  String get uid => currentUser!.uid;

  Stream<User?> get authStateChanges => _inst.authStateChanges();

  DocumentReference<Map<String, dynamic>> get userDoc => _userDocRef(uid);

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) {
    return FirebaseFirestore.instance.collection("users").doc(uid);
  }

  Future<void> refreshUser() async {
    await _inst.currentUser?.reload();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required Map<String, dynamic> userDocumentData,
  }) async {
    var credential = await _inst.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    credential.user!.sendEmailVerification();
    credential.user!.updateDisplayName(displayName);

    userDoc.set(userDocumentData);
  }

  Future<void> login({required String email, required String password}) async {
    await _inst.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Giriş işlemi başarılı olduğunda authStateChanges tetiklenir.
  /// [verificationCompleted] parametresine sayfa yönlendirme metodu yazılmasına gerek yoktur.
  /// Gerçi zaten [verificationCompleted] ve [verificationFailed] metodlarını hiçbir şekilde tetiklettiremedim.
  /// O yüzden metodları parametrelerden sildim. Tetiklemeyi bir gün öğrenirsem eklerim.
  Future<void> loginPhone({
    required String phoneNumber,
    required void Function(String verificationId, Duration timeout) codeSent,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final phoneRegEx = RegExp(r"^(?:(?:(?:00|\+)([0-9]\d*))|0|)(\d{11})$");
    final firstMatch = phoneRegEx.firstMatch(phoneNumber);
    final phoneInCorrectForm = (firstMatch?.group(1)?.isNotEmpty ?? false ? "+${firstMatch!.group(1)!}" : "+90") + firstMatch!.group(2)!;

    await _inst.setSettings(appVerificationDisabledForTesting: true, forceRecaptchaFlow: false);
    await _inst.verifyPhoneNumber(
      timeout: timeout,
      forceResendingToken: 0,
      phoneNumber: phoneInCorrectForm,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId, timeout);
      },
      verificationFailed: (_) {},
      verificationCompleted: (_) {},
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void enterVerificationCode({
    required String smsCode,
    required String verificationId,
    required Map<String, dynamic> userDocumentMap,
    required void Function(String errorMessage) onError,
  }) async {
    try {
      var trimedSmsCode = smsCode.trim();
      var credential = PhoneAuthProvider.credential(smsCode: trimedSmsCode, verificationId: verificationId);
      await _inst.signInWithCredential(credential);

      var doc = await userDoc.get();
      if (!doc.exists) await userDoc.set(userDocumentMap);
    } on FirebaseAuthException catch (e) {
      onError(Errors.fromFirebase(e));
    }
  }

  Future<void> logout() => _inst.signOut();

  Future<bool> deleteAccount() async {
    await userDoc.delete();
    await currentUser!.delete();
    return true;
  }
}
