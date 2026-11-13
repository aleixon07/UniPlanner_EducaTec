import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../model/usuario.dart';

/// Erro de cadastro já traduzido para mostrar na tela.
class ErroCadastro implements Exception {
  final String mensagem;
  const ErroCadastro(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso aos usuários (alunos, professores e administradores).
///
/// É uma classe abstrata para as telas poderem ser testadas sem Firebase:
/// os testes trocam [instancia] por uma versão falsa.
abstract class UsuarioService {
  static UsuarioService instancia = FirebaseUsuarioService();

  /// Usuários do [perfil], em ordem alfabética, sempre atualizados.
  Stream<List<Usuario>> listar(PerfilUsuario perfil);

  /// Todos os usuários, de qualquer perfil, sempre atualizados.
  Stream<List<Usuario>> todos();

  /// Cria a conta de login e o cadastro do usuário. [cursoId] vale só para
  /// alunos (professor ignora). Lança [ErroCadastro].
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
    String? cursoId,
  });

  /// Muda o nome do usuário e, se for aluno, o curso ([cursoId] `null` tira o
  /// aluno do curso). O e-mail e a senha não mudam aqui: trocar a conta de
  /// login de outra pessoa exige o Firebase Admin (Cloud Functions), que o app
  /// não tem. Lança [ErroCadastro].
  Future<void> editar(Usuario usuario, String nome, {String? cursoId});

  /// Desativa ou reativa o usuário. Um usuário desativado não consegue entrar
  /// (veja [AuthService.entrar]). Lança [ErroCadastro].
  Future<void> definirAtivo(String id, bool ativo);
}

class FirebaseUsuarioService implements UsuarioService {
  // Só toca no Firebase quando é usado, para criar o objeto não exigir
  // Firebase.initializeApp().
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('usuarios');

  @override
  Stream<List<Usuario>> listar(PerfilUsuario perfil) {
    return _colecao.where('perfil', isEqualTo: perfil.name).snapshots().map((
      resultado,
    ) {
      final lista = resultado.docs
          .map((doc) => Usuario.fromMap(doc.id, doc.data()))
          .toList();
      lista.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
      return lista;
    });
  }

  @override
  Stream<List<Usuario>> todos() => _colecao.snapshots().map(
    (r) => [for (final doc in r.docs) Usuario.fromMap(doc.id, doc.data())],
  );

  @override
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
    String? cursoId,
  }) async {
    final emailLimpo = email.trim().toLowerCase();

    // Criar a conta pelo Firebase principal deslogaria o administrador e
    // entraria como o usuário novo. Por isso a conta nasce num app secundário,
    // descartado no final. O Firestore, abaixo, é gravado pelo app principal,
    // ou seja, ainda como administrador.
    final appSecundario = await Firebase.initializeApp(
      name: 'cadastro-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final auth = FirebaseAuth.instanceFor(app: appSecundario);

      final UserCredential credencial;
      try {
        credencial = await auth.createUserWithEmailAndPassword(
          email: emailLimpo,
          password: senha,
        );
      } on FirebaseAuthException catch (e) {
        throw ErroCadastro(_traduzirAuth(e.code));
      }

      final conta = credencial.user!;

      try {
        await _colecao.doc(conta.uid).set({
          ...Usuario(
            id: conta.uid,
            nome: nome.trim(),
            email: emailLimpo,
            perfil: perfil,
            cursoId: perfil == PerfilUsuario.aluno ? cursoId : null,
            senhaTemporaria: true,
          ).toMap(),
          'criadoEm': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        await _desfazerConta(conta);
        throw ErroCadastro(
          e.code == 'permission-denied'
              ? 'Sem permissão para salvar. Verifique as regras do Firestore.'
              : 'Não foi possível salvar os dados do usuário. Tente novamente.',
        );
      }
    } finally {
      try {
        await appSecundario.delete();
      } catch (_) {
        // Falhar ao limpar o app temporário não pode esconder o resultado.
      }
    }
  }

  @override
  Future<void> editar(Usuario usuario, String nome, {String? cursoId}) async {
    final limpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpo.isEmpty) throw const ErroCadastro('Informe o nome.');

    await _atualizar(usuario.id, {
      'nome': limpo,
      // Só aluno tem curso; sem curso, o campo é apagado do documento.
      if (usuario.perfil == PerfilUsuario.aluno)
        'cursoId': cursoId ?? FieldValue.delete(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> definirAtivo(String id, bool ativo) {
    return _atualizar(id, {
      'ativo': ativo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _atualizar(String id, Map<String, Object?> campos) async {
    try {
      await _colecao.doc(id).update(campos);
    } on FirebaseException catch (e) {
      throw ErroCadastro(switch (e.code) {
        'permission-denied' =>
          'Sem permissão para salvar. Verifique as regras do Firestore.',
        'unavailable' => 'Sem conexão. Verifique sua internet.',
        'not-found' => 'Este usuário não existe mais.',
        _ => 'Não foi possível salvar o usuário (${e.code}).',
      });
    }
  }

  /// Apaga a conta que acabou de ser criada, para não sobrar um login sem
  /// cadastro quando a gravação no Firestore falha.
  Future<void> _desfazerConta(User conta) async {
    try {
      await conta.delete();
    } catch (_) {}
  }

  String _traduzirAuth(String codigo) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha não está habilitado no Firebase.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet.';
      default:
        return 'Não foi possível criar a conta ($codigo).';
    }
  }
}
