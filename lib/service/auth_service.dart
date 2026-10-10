import 'package:firebase_auth/firebase_auth.dart';

/// Erro de autenticação já traduzido para mostrar na tela.
class ErroAuth implements Exception {
  final String mensagem;
  const ErroAuth(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Ponto único de contato com o Firebase Authentication.
///
/// TODO(RF001/ADR-001): hoje o login é por e-mail, porque o Firebase Auth não
/// tem provedor de CPF. Quando a decisão do CPF for tomada, é aqui que ela
/// entra — a tela de login não precisa saber como o CPF vira credencial.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Usuário logado no momento, ou `null`.
  static User? get usuarioAtual => _auth.currentUser;

  /// Avisa sempre que o usuário entra ou sai.
  static Stream<User?> get mudancasDeLogin => _auth.authStateChanges();

  /// Entra com e-mail e senha. Lança [ErroAuth] com mensagem pronta.
  static Future<User> entrar({
    required String email,
    required String senha,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      final usuario = credencial.user;
      if (usuario == null) {
        throw const ErroAuth('Não foi possível entrar. Tente novamente.');
      }
      return usuario;
    } on FirebaseAuthException catch (e) {
      throw ErroAuth(_traduzir(e.code));
    }
  }

  static Future<void> sair() => _auth.signOut();

  /// O Firebase devolve códigos em inglês; a tela precisa de português.
  static String _traduzir(String codigo) {
    switch (codigo) {
      // O Firebase unificou "usuário não existe" e "senha errada" num código
      // só, de propósito: dizer qual dos dois errou entrega quais e-mails
      // estão cadastrados.
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'user-not-found':
      case 'wrong-password':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta está desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha não está habilitado no Firebase.';
      default:
        return 'Não foi possível entrar ($codigo).';
    }
  }
}
