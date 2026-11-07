import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/curso.dart';

/// Erro de curso já traduzido para mostrar na tela.
class ErroCurso implements Exception {
  final String mensagem;
  const ErroCurso(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso aos cursos (RF011/UC011).
///
/// Mesmo modelo do [UsuarioService] e do [SalaService]: classe abstrata, para
/// as telas poderem ser testadas sem Firebase trocando [instancia].
///
/// O CRUD é: cadastrar (create), listar/observar (read), editar e
/// definirAtivo (update). Não existe apagar de verdade: um curso errado ou
/// encerrado é desativado, porque disciplinas e turmas vão apontar para ele.
abstract class CursoService {
  static CursoService instancia = FirebaseCursoService();

  /// Todos os cursos, ativos e inativos, em ordem alfabética, sempre
  /// atualizados.
  Stream<List<Curso>> listar();

  /// Um curso, sempre atualizado. Emite `null` se ele não existir (mais).
  Stream<Curso?> observar(String id);

  /// Cadastra um curso. Lança [ErroCurso] se o nome já existir ou se der erro.
  Future<void> cadastrar(String nome);

  /// Muda o nome do curso. Lança [ErroCurso].
  Future<void> editar(String id, String nome);

  /// Desativa ou reativa o curso. Lança [ErroCurso].
  Future<void> definirAtivo(String id, bool ativo);
}

class FirebaseCursoService implements CursoService {
  // Só toca no Firebase quando é usado, para criar o objeto não exigir
  // Firebase.initializeApp().
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('cursos');

  @override
  Stream<List<Curso>> listar() {
    return _colecao.snapshots().map((resultado) {
      final lista = resultado.docs
          .map((doc) => Curso.fromMap(doc.id, doc.data()))
          .toList();
      lista.sort(
        (a, b) => Curso.chaveNome(a.nome).compareTo(Curso.chaveNome(b.nome)),
      );
      return lista;
    });
  }

  @override
  Stream<Curso?> observar(String id) {
    return _colecao.doc(id).snapshots().map((doc) {
      final dados = doc.data();
      return dados == null ? null : Curso.fromMap(doc.id, dados);
    });
  }

  @override
  Future<void> cadastrar(String nome) async {
    final limpo = _limpar(nome);

    try {
      await _garantirNomeLivre(limpo);
      await _colecao.add({
        ...Curso(id: '', nome: limpo).toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroCurso(_traduzir(e.code));
    }
  }

  @override
  Future<void> editar(String id, String nome) async {
    final limpo = _limpar(nome);

    try {
      await _garantirNomeLivre(limpo, ignorarId: id);
      await _colecao.doc(id).update({
        'nome': limpo,
        'nomeBusca': Curso.chaveNome(limpo),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroCurso(_traduzir(e.code));
    }
  }

  @override
  Future<void> definirAtivo(String id, bool ativo) async {
    try {
      await _colecao.doc(id).update({
        'ativo': ativo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroCurso(_traduzir(e.code));
    }
  }

  /// Tira espaços das pontas e repetidos no meio, e recusa nome vazio.
  String _limpar(String nome) {
    final limpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpo.isEmpty) throw const ErroCurso('Informe o nome do curso.');
    return limpo;
  }

  /// Procura outro curso com o mesmo nome (ignorando maiúsculas, acentos e
  /// espaços). [ignorarId] é o curso que está sendo editado, para ele não
  /// conflitar consigo mesmo.
  ///
  /// A checagem e a gravação são dois passos, então dois administradores
  /// cadastrando o mesmo nome no mesmo instante poderiam passar os dois. Para
  /// uma tela de administração isso é aceitável; se virar problema, o caminho
  /// é um documento-trava por nome dentro de uma transação.
  Future<void> _garantirNomeLivre(String nome, {String? ignorarId}) async {
    final iguais = await _colecao
        .where('nomeBusca', isEqualTo: Curso.chaveNome(nome))
        .get();

    if (iguais.docs.any((doc) => doc.id != ignorarId)) {
      throw const ErroCurso('Já existe um curso com esse nome.');
    }
  }

  String _traduzir(String codigo) {
    switch (codigo) {
      case 'permission-denied':
        return 'Sem permissão para salvar. Verifique as regras do Firestore.';
      case 'unavailable':
        return 'Sem conexão. Verifique sua internet.';
      case 'not-found':
        return 'Este curso não existe mais.';
      default:
        return 'Não foi possível salvar o curso ($codigo).';
    }
  }
}
