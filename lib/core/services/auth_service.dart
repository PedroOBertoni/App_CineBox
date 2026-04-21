import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String plan,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'plan': plan,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<String?> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Erro inesperado. Tente novamente.';
    }
  }

  // Retorna null em sucesso, 'NEW_USER' se for primeiro acesso, ou mensagem de erro
  Future<String?> signInWithGoogle({required bool rememberMe}) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'cancelled';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);

      // Verifica se é novo usuário
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'name': cred.user!.displayName ?? googleUser.displayName ?? '',
          'email': cred.user!.email ?? '',
          'plan': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return 'NEW_USER';
      }

      // Usuário existente — verifica se ainda não escolheu plano
      final plan = doc.data()?['plan'] ?? '';
      if (plan.isEmpty) return 'NEW_USER';

      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'Erro inesperado. Tente novamente.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<String?> updatePlan(String uid, String plan) async {
    try {
      await _db.collection('users').doc(uid).update({'plan': plan});
      return null;
    } catch (e) {
      return 'Erro ao atualizar plano.';
    }
  }

  String _authError(String code) {
    debugPrint('FirebaseAuthException code: $code');
    switch (code) {
      case 'email-already-in-use': return 'E-mail já cadastrado.';
      case 'invalid-email': return 'E-mail inválido.';
      case 'weak-password': return 'Senha muito fraca.';
      case 'user-not-found': return 'Usuário não encontrado.';
      case 'wrong-password': return 'Senha incorreta.';
      case 'invalid-credential': return 'E-mail ou senha incorretos.';
      case 'too-many-requests': return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'user-disabled': return 'Esta conta foi desativada.';
      case 'network-request-failed': return 'Sem conexão. Verifique sua internet.';
      case 'INVALID_LOGIN_CREDENTIALS': return 'E-mail ou senha incorretos.';
      default: return 'Erro ($code). Tente novamente.';
    }
  }
}
