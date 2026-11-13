enum PerfilUsuario { aluno, professor, administrador }

extension PerfilUsuarioInfo on PerfilUsuario {
  String get rotulo => switch (this) {
    PerfilUsuario.aluno => 'Aluno',
    PerfilUsuario.professor => 'Professor',
    PerfilUsuario.administrador => 'Administrador',
  };

  String get rotuloPlural => switch (this) {
    PerfilUsuario.aluno => 'Alunos',
    PerfilUsuario.professor => 'Professores',
    PerfilUsuario.administrador => 'Administradores',
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

  /// Curso do aluno (id em `cursos`). Só alunos usam; fica `null` para
  /// professores e para alunos ainda sem curso.
  final String? cursoId;

  /// `true` enquanto a pessoa ainda usa a senha temporária do cadastro. No
  /// primeiro login ela é obrigada a trocar.
  final bool senhaTemporaria;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.ativo = true,
    this.cursoId,
    this.senhaTemporaria = false,
  });

  Map<String, Object?> toMap() => {
    'nome': nome,
    'email': email,
    'perfil': perfil.name,
    'ativo': ativo,
    if (cursoId != null) 'cursoId': cursoId,
    'senhaTemporaria': senhaTemporaria,
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
      cursoId: dados['cursoId'] as String?,
      senhaTemporaria: (dados['senhaTemporaria'] as bool?) ?? false,
    );
  }
}
