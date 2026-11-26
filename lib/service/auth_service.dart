import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/usuario.dart';
import 'lembretes.dart';
import 'sessao.dart';

/// Erro de autenticação já traduzido para mostrar na tela.
class ErroAuth implements Exception {
  final String mensagem;
  const ErroAuth(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Ponto único de contato com o Firebase Authentication.
///
/// O login é por e-mail e senha (o CPF foi descartado). Depois de autenticar,
/// carrega o cadastro em `usuarios/{uid}` e guarda na [Sessao]: é o cadastro
/// que diz o perfil (aluno, professor ou administrador).
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _usuarios =>
      FirebaseFirestore.instance.collection('usuarios');

  /// Usuário logado no momento, ou `null`.
  static User? get usuarioAtual => _auth.currentUser;

  /// Avisa sempre que o usuário entra ou sai.
  static Stream<User?> get mudancasDeLogin => _auth.authStateChanges();

  /// Entra com e-mail e senha e devolve o cadastro (com o perfil). Lança
  /// [ErroAuth] com mensagem pronta.
  ///
  /// Se o cadastro estiver com `senhaTemporaria`, quem chamou deve obrigar a
  /// troca da senha antes de liberar o app.
  static Future<Usuario> entrar({
    required String email,
    required String senha,
  }) async {
    final User conta;
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final usuario = credencial.user;
      if (usuario == null) {
        throw const ErroAuth('Não foi possível entrar. Tente novamente.');
      }
      conta = usuario;
    } on FirebaseAuthException catch (e) {
      throw ErroAuth(_traduzir(e.code));
    }

    final cadastro = await _carregarCadastro(conta);
    Sessao.atual.value = cadastro;
    return cadastro;
  }

  /// Lê o cadastro da conta e decide se ela pode entrar.
  ///
  /// - Desativada pelo administrador: não entra.
  /// - Sem cadastro: só pode acontecer com conta criada à mão no console do
  ///   Firebase (o app sempre cria os dois juntos). Se ainda não existe nenhum
  ///   administrador, essa conta vira o primeiro administrador; depois disso,
  ///   conta sem cadastro não entra.
  /// - Se não der para consultar o cadastro, o acesso é negado: na dúvida, uma
  ///   conta desativada não deve passar.
  ///
  /// Limite: isto só vale no momento do login. Quem já estava logado continua
  /// até sair; para barrar na hora, é preciso desativar a conta no Firebase
  /// Auth (Admin) ou checar `ativo` nas regras do Firestore.
  static Future<Usuario> _carregarCadastro(User conta) async {
    try {
      final doc = await _usuarios.doc(conta.uid).get();
      final dados = doc.data();

      if (dados == null) return await _criarPrimeiroAdministrador(conta);

      final usuario = Usuario.fromMap(doc.id, dados);
      if (!usuario.ativo) {
        throw const ErroAuth('Esta conta está desativada.');
      }
      return usuario;
    } on ErroAuth {
      await _auth.signOut();
      rethrow;
    } on FirebaseException {
      await _auth.signOut();
      throw const ErroAuth(
        'Não foi possível verificar a conta. Tente novamente.',
      );
    }
  }

  static Future<Usuario> _criarPrimeiroAdministrador(User conta) async {
    final administradores = await _usuarios
        .where('perfil', isEqualTo: PerfilUsuario.administrador.name)
        .limit(1)
        .get();

    if (administradores.docs.isNotEmpty) {
      throw const ErroAuth(
        'Esta conta não tem cadastro no UniPlanner. '
        'Fale com o administrador.',
      );
    }

    final email = conta.email ?? '';
    final usuario = Usuario(
      id: conta.uid,
      nome: conta.displayName ?? email.split('@').first,
      email: email,
      perfil: PerfilUsuario.administrador,
    );
    await _usuarios.doc(conta.uid).set({
      ...usuario.toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return usuario;
  }

  /// Troca a senha temporária pela [nova], no primeiro login. [atual] é a
  /// senha temporária que acabou de ser usada para entrar. Lança [ErroAuth].
  static Future<void> trocarSenhaTemporaria({
    required String atual,
    required String nova,
  }) async {
    final conta = _auth.currentUser;
    final cadastro = Sessao.usuario;
    if (conta == null || cadastro == null) {
      throw const ErroAuth('Sessão expirada. Entre de novo.');
    }
    if (nova == atual) {
      throw const ErroAuth('A nova senha precisa ser diferente da temporária.');
    }

    try {
      // O Firebase só deixa trocar a senha de um login recente; confirmar a
      // senha atual garante isso mesmo se o app ficou parado no modal.
      await conta.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: conta.email ?? '', password: atual),
      );
      await conta.updatePassword(nova);
    } on FirebaseAuthException catch (e) {
      throw ErroAuth(_traduzir(e.code));
    }

    try {
      await _usuarios.doc(conta.uid).update({
        'senhaTemporaria': false,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // A senha já mudou; se só a marcação falhar, no próximo login o modal
      // aparece de novo e a pessoa troca outra vez. Não vale travar o acesso.
    }

    Sessao.atual.value = Usuario(
      id: cadastro.id,
      nome: cadastro.nome,
      email: cadastro.email,
      perfil: cadastro.perfil,
      ativo: cadastro.ativo,
      cursoId: cadastro.cursoId,
    );
  }

  /// Envia o e-mail de redefinição de senha do Firebase. O e-mail traz um
  /// link; a senha nova é definida na página do Firebase que o link abre.
  /// Lança [ErroAuth].
  ///
  /// Por segurança o Firebase não conta se o e-mail existe: a resposta é a
  /// mesma para e-mail cadastrado ou não, para ninguém descobrir quem tem conta.
  static Future<void> enviarRedefinicaoDeSenha(String email) async {
    try {
      await _auth.setLanguageCode('pt');
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Conta inexistente não é erro para quem está na tela (veja acima).
      if (e.code == 'user-not-found') return;
      throw ErroAuth(_traduzir(e.code));
    }
  }

  /// Ao abrir o app: se já existe uma conta logada neste aparelho, carrega o
  /// cadastro dela sem pedir a senha de novo. Devolve `null` quando a pessoa
  /// precisa passar pela tela de login.
  ///
  /// - Sem conta salva: `null`.
  /// - Sem conexão: `null`, mas a sessão do Firebase é mantida (não é
  ///   culpa da pessoa estar sem internet no momento de abrir o app).
  /// - Desativada ou ainda com senha temporária: sai da conta e devolve `null`.
  static Future<Usuario?> restaurarSessao() async {
    final conta = _auth.currentUser;
    if (conta == null) return null;

    final DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _usuarios.doc(conta.uid).get();
    } on FirebaseException {
      return null;
    }

    final dados = doc.data();
    // Sem cadastro: o login é quem decide (por exemplo, o primeiro administrador).
    if (dados == null) return null;

    final usuario = Usuario.fromMap(doc.id, dados);
    if (!usuario.ativo || usuario.senhaTemporaria) {
      await sair();
      return null;
    }

    Sessao.atual.value = usuario;
    return usuario;
  }

  static Future<void> sair() async {
    // Quem entrar depois neste aparelho não deve receber as aulas de quem saiu.
    await Lembretes.parar();
    Sessao.atual.value = null;
    await _auth.signOut();
  }

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
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'requires-recent-login':
        return 'Por segurança, entre de novo e troque a senha.';
      default:
        return 'Não foi possível entrar ($codigo).';
    }
  }
}
