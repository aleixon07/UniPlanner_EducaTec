import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/disciplina.dart';
import '../model/semestre.dart';

/// Erro de disciplina já traduzido para mostrar na tela.
class ErroDisciplina implements Exception {
  final String mensagem;
  const ErroDisciplina(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso às disciplinas dos semestres.
///
/// CRUD: [adicionar] (create), [listar] (read), [editar] (update) e
/// [excluir] (delete). Uma disciplina pertence a um semestre e não pode ter o
/// mesmo nome de outra do mesmo semestre.
abstract class DisciplinaService {
  static DisciplinaService instancia = FirebaseDisciplinaService();

  /// Disciplinas de um curso (de todos os semestres), em ordem alfabética,
  /// sempre atualizadas. A tela separa por semestre.
  Stream<List<Disciplina>> listar(String cursoId);

  /// Cria a disciplina no semestre. Lança [ErroDisciplina] se o nome estiver
  /// vazio, repetido no semestre ou se der erro.
  Future<void> adicionar(Semestre semestre, String nome);

  /// Uma disciplina, sempre atualizada. Emite `null` se ela não existir (mais).
  Stream<Disciplina?> observar(String id);

  /// Vincula um professor (pelo uid) à disciplina. Lança [ErroDisciplina].
  Future<void> adicionarProfessor(Disciplina disciplina, String professorId);

  /// Desvincula o professor da disciplina. Lança [ErroDisciplina].
  Future<void> removerProfessor(Disciplina disciplina, String professorId);

  /// Muda o nome da disciplina. Lança [ErroDisciplina].
  Future<void> editar(Disciplina disciplina, String nome);

  /// Exclui a disciplina. Lança [ErroDisciplina].
  Future<void> excluir(Disciplina disciplina);
}

class FirebaseDisciplinaService implements DisciplinaService {
  static const int tamanhoMaximoNome = 80;

  // Só toca no Firebase quando é usado.
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('disciplinas');

  @override
  Stream<List<Disciplina>> listar(String cursoId) {
    return _colecao.where('cursoId', isEqualTo: cursoId).snapshots().map((
      resultado,
    ) {
      final lista = resultado.docs
          .map((doc) => Disciplina.fromMap(doc.id, doc.data()))
          .toList();
      lista.sort(
        (a, b) =>
            Disciplina.chaveNome(a.nome)
                .compareTo(Disciplina.chaveNome(b.nome)),
      );
      return lista;
    });
  }

  @override
  Stream<Disciplina?> observar(String id) {
    return _colecao.doc(id).snapshots().map((doc) {
      final dados = doc.data();
      return dados == null ? null : Disciplina.fromMap(doc.id, dados);
    });
  }

  // arrayUnion/arrayRemove mexem só na lista, sem reescrever o documento: dois
  // administradores adicionando professores ao mesmo tempo não se atropelam.
  @override
  Future<void> adicionarProfessor(
    Disciplina disciplina,
    String professorId,
  ) async {
    try {
      await _colecao.doc(disciplina.id).update({
        'professorIds': FieldValue.arrayUnion([professorId]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroDisciplina(_traduzir(e.code));
    }
  }

  @override
  Future<void> removerProfessor(
    Disciplina disciplina,
    String professorId,
  ) async {
    try {
      await _colecao.doc(disciplina.id).update({
        'professorIds': FieldValue.arrayRemove([professorId]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroDisciplina(_traduzir(e.code));
    }
  }

  String _limpar(String nome) {
    final limpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpo.isEmpty) {
      throw const ErroDisciplina('Informe o nome da disciplina.');
    }
    if (limpo.length > tamanhoMaximoNome) {
      throw const ErroDisciplina(
        'O nome pode ter no máximo $tamanhoMaximoNome caracteres.',
      );
    }
    return limpo;
  }

  Future<void> _garantirNomeLivre(
    String semestreId,
    String nome, {
    String? ignorarId,
  }) async {
    final existentes = await _colecao
        .where('semestreId', isEqualTo: semestreId)
        .get();
    final chave = Disciplina.chaveNome(nome);
    final repetido = existentes.docs.any(
      (doc) =>
          doc.id != ignorarId &&
          Disciplina.chaveNome((doc.data()['nome'] as String?) ?? '') == chave,
    );
    if (repetido) {
      throw const ErroDisciplina('Este semestre já tem essa disciplina.');
    }
  }

  @override
  Future<void> adicionar(Semestre semestre, String nome) async {
    final limpo = _limpar(nome);
    try {
      await _garantirNomeLivre(semestre.id, limpo);
      await _colecao.add({
        ...Disciplina(
          id: '',
          cursoId: semestre.cursoId,
          semestreId: semestre.id,
          nome: limpo,
        ).toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroDisciplina(_traduzir(e.code));
    }
  }

  @override
  Future<void> editar(Disciplina disciplina, String nome) async {
    final limpo = _limpar(nome);
    try {
      await _garantirNomeLivre(
        disciplina.semestreId,
        limpo,
        ignorarId: disciplina.id,
      );
      await _colecao.doc(disciplina.id).update({
        'nome': limpo,
        'nomeBusca': Disciplina.chaveNome(limpo),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroDisciplina(_traduzir(e.code));
    }
  }

  @override
  Future<void> excluir(Disciplina disciplina) async {
    try {
      await _colecao.doc(disciplina.id).delete();
    } on FirebaseException catch (e) {
      throw ErroDisciplina(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) {
    switch (codigo) {
      case 'permission-denied':
        return 'Sem permissão para salvar. Verifique as regras do Firestore.';
      case 'unavailable':
        return 'Sem conexão. Verifique sua internet.';
      case 'not-found':
        return 'Esta disciplina não existe mais.';
      default:
        return 'Não foi possível salvar a disciplina ($codigo).';
    }
  }
}
