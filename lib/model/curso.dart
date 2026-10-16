/// Curso oferecido pela instituição (RF011/UC011).
///
/// Um curso desativado continua cadastrado, só deixa de estar disponível.
class Curso {
  final String id;
  final String nome;
  final bool ativo;

  const Curso({required this.id, required this.nome, this.ativo = true});

  Curso copyWith({String? nome, bool? ativo}) {
    return Curso(id: id, nome: nome ?? this.nome, ativo: ativo ?? this.ativo);
  }
}
