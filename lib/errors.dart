import 'package:firebase_auth/firebase_auth.dart';

class Errors {
  static String fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Girdiğiniz e-posta formatı geçersiz.';
      case 'wrong-password':
        return 'Girdiğiniz şifre yanlış.';
      case 'user-not-found':
        return "Girdiğiniz e-postaya sahip kullanıcı bulunamadı.";
      case 'user-disabled':
        return 'Bu hesap şu anda kullanım dışı. Başka bir email ile kayıt olabilirsiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta ile zaten bir hesap mevcut.';
      case 'weak-password':
        return 'Girdiğiniz şifre çok zayıf.';
      case 'operation-not-allowed':
        return '(operation-not-allowed): Kullanıcı kayıt sağlayıcısı aktif değil.';
      case 'unknown':
        return 'Bilinmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
      default:
        return e.message.toString();
    }
  }
}
