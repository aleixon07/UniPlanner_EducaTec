/// Disciplina de um semestre de um curso (por exemplo, "Banco de Dados" no
/// 3º semestre de Sistemas de Informação).
///
/// Fica na coleção `disciplinas` do Firestore, com id automático. O vínculo é
/// o [semestreId] (e o [cursoId], guardado junto para facilitar consultas).
class Disciplina {
  final String id;
  final String cursoId;
  final String semestreId;
  final String nome;

  /// Ids (uid) dos professores que dão esta disciplina.
  final List<String> professorIds;

  const Disciplina({
    required this.id,
    required this.cursoId,
    required this.semestreId,
    required this.nome,
    this.professorIds = const [],
  });

  /// Chave para comparar nomes: minúsculas, sem acentos e sem espaços
  /// repetidos. "Cálculo  I" e "calculo i" são a mesma disciplina.
  static String chaveNome(String nome) {
    const com = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const sem = 'aaaaaeeeeiiiiooooouuuucn';
    var chave = nome.trim().toLowerCase();
    for (var i = 0; i < com.length; i++) {
      chave = chave.replaceAll(com[i], sem[i]);
    }
    return chave.replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, Object?> toMap() => {
    'cursoId': cursoId,
    'semestreId': semestreId,
    'nome': nome,
    'nomeBusca': chaveNome(nome),
    'professorIds': professorIds,
  };

  factory Disciplina.fromMap(String id, Map<String, dynamic> dados) {
    return Disciplina(
      id: id,
      cursoId: (dados['cursoId'] as String?) ?? '',
      semestreId: (dados['semestreId'] as String?) ?? '',
      nome: (dados['nome'] as String?) ?? '',
      professorIds: [...?(dados['professorIds'] as List?)?.whereType<String>()],
    );
  }
}
