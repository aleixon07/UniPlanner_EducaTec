/// Curso oferecido pela instituição (RF011/UC011).
///
/// Fica na coleção `cursos` do Firestore, com id gerado automaticamente (o nome
/// pode ser editado, então não serve de id). Um curso desativado continua
/// cadastrado, só deixa de estar disponível.
class Curso {
  final String id;
  final String nome;
  final bool ativo;

  const Curso({required this.id, required this.nome, this.ativo = true});

  Curso copyWith({String? nome, bool? ativo}) {
    return Curso(id: id, nome: nome ?? this.nome, ativo: ativo ?? this.ativo);
  }

  /// Nome "achatado" para comparar cursos: sem maiúsculas, sem acentos e com
  /// espaços repetidos reduzidos a um. Assim "Técnico  em Informática" e
  /// "tecnico em informatica" contam como o mesmo curso.
  static String chaveNome(String nome) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const semAcento = 'aaaaaeeeeiiiiooooouuuuc';

    final saida = StringBuffer();
    for (final letra in nome.toLowerCase().split('')) {
      final i = comAcento.indexOf(letra);
      saida.write(i == -1 ? letra : semAcento[i]);
    }
    return saida.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// `nomeBusca` é a [chaveNome], guardada para o Firestore poder procurar
  /// um curso de mesmo nome.
  Map<String, Object?> toMap() => {
    'nome': nome,
    'nomeBusca': chaveNome(nome),
    'ativo': ativo,
  };

  factory Curso.fromMap(String id, Map<String, dynamic> dados) {
    return Curso(
      id: id,
      nome: (dados['nome'] as String?) ?? '',
      ativo: (dados['ativo'] as bool?) ?? true,
    );
  }
}
