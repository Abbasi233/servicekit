library servicekit;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'errors.dart';

abstract class ServiceKit {
  FirebaseAuth get _inst => FirebaseAuth.instance;

  User? get currentUser => _inst.currentUser;

  String get uid => currentUser!.uid;

  Stream<User?> get authStateChanges => _inst.authStateChanges();

  DocumentReference<Map<String, dynamic>> get userDoc => _userDocRef(uid);

  Future<String?>? get idToken => currentUser?.getIdToken();

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) {
    return FirebaseFirestore.instance.collection("Users").doc(uid);
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
    UserCredential credential;

    try {
      credential = await _inst.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Errors.fromFirebase(e);
    } on Exception catch (_) {
      rethrow;
    }

    credential.user!.sendEmailVerification();
    credential.user!.updateDisplayName(displayName);

    userDoc.set(userDocumentData);
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _inst.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Errors.fromFirebase(e);
    } on Exception catch (_) {
      rethrow;
    }
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

    // await _inst.setSettings(appVerificationDisabledForTesting: true, forceRecaptchaFlow: false);
    await _inst.verifyPhoneNumber(
      timeout: timeout,
      forceResendingToken: 0,
      phoneNumber: phoneInCorrectForm,
      verificationFailed: (_) {},
      verificationCompleted: (_) {},
      codeAutoRetrievalTimeout: (_) {},
      codeSent: (String verificationId, int? resendToken) => codeSent(verificationId, timeout),
    );
  }

  Future<void> enterVerificationCode({
    required String smsCode,
    required String verificationId,
    required Map<String, dynamic> userDocumentMap,
    required void Function(String errorMessage) onError,
    bool savePhoneNumberToUserDoc = false,
  }) async {
    try {
      var trimedSmsCode = smsCode.trim();
      var credential = PhoneAuthProvider.credential(smsCode: trimedSmsCode, verificationId: verificationId);
      await _inst.signInWithCredential(credential);

      var doc = await userDoc.get();
      if (!doc.exists) {
        if (savePhoneNumberToUserDoc) {
          userDocumentMap["phone"] = currentUser?.phoneNumber;
        }
        await userDoc.set(userDocumentMap);
      }
      // currentUser?.updatePhoneNumber(credential);
    } on FirebaseAuthException catch (e) {
      onError(Errors.fromFirebase(e));
    }
  }

  Future<void> loginWithGoogle(Map<String, dynamic> userDocumentMap) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _inst.signInWithCredential(credential);

      var doc = await userDoc.get();
      if (!doc.exists) {
        userDocumentMap["email"] = currentUser?.email;
        await userDoc.set(userDocumentMap);
      }
    } on FirebaseAuthException catch (e) {
      throw Errors.fromFirebase(e);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> loginWithApple(Map<String, dynamic> userDocumentMap) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _inst.signInWithCredential(oauthCredential);

      var doc = await userDoc.get();
      if (!doc.exists) {
        userDocumentMap["email"] = currentUser?.email;
        await userDoc.set(userDocumentMap);
      }
    } on FirebaseAuthException catch (e) {
      throw Errors.fromFirebase(e);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> logout() => _inst.signOut();

  Future<bool> deleteAccount() async {
    await userDoc.delete();
    await currentUser!.delete();
    return true;
  }
}
