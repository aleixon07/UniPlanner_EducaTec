enum PerfilUsuario { aluno, professor }

extension PerfilUsuarioInfo on PerfilUsuario {
  String get rotulo => switch (this) {
    PerfilUsuario.aluno => 'Aluno',
    PerfilUsuario.professor => 'Professor',
  };

  String get rotuloPlural => switch (this) {
    PerfilUsuario.aluno => 'Alunos',
    PerfilUsuario.professor => 'Professores',
  };
}

/// Pessoa cadastrada no sistema (RF011/UC009).
///
/// O [id] é o `uid` da conta no Firebase Authentication, o mesmo id do
/// documento na coleção `usuarios` do Firestore. A senha nunca fica aqui:
/// ela existe só no Authentication.
class Usuario {
  final String id;
  final String nome;
  final String email;
  final PerfilUsuario perfil;
  final bool ativo;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.ativo = true,
  });

  Map<String, Object?> toMap() => {
    'nome': nome,
    'email': email,
    'perfil': perfil.name,
    'ativo': ativo,
  };

  factory Usuario.fromMap(String id, Map<String, dynamic> dados) {
    return Usuario(
      id: id,
      nome: (dados['nome'] as String?) ?? '',
      email: (dados['email'] as String?) ?? '',
      perfil: PerfilUsuario.values.firstWhere(
        (p) => p.name == dados['perfil'],
        orElse: () => PerfilUsuario.aluno,
      ),
      ativo: (dados['ativo'] as bool?) ?? true,
    );
  }
}
