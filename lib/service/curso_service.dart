import '../model/curso.dart';

/// Fonte de dados dos cursos.
///
/// Por enquanto tudo fica em memória, com cursos fictícios, só para as telas
/// funcionarem. Quando o Firestore entrar, é este arquivo que muda.
class CursoService {
  CursoService._();

  static int _proximoId = 5;

  static final List<Curso> _cursos = [
    const Curso(id: '1', nome: 'Sistemas de Informação'),
    const Curso(id: '2', nome: 'Técnico em Informática'),
    const Curso(id: '3', nome: 'Técnico em Administração'),
    const Curso(id: '4', nome: 'Licenciatura em Matemática', ativo: false),
  ];

  static List<Curso> get cursos => List.unmodifiable(_cursos);

  static Curso? buscar(String id) {
    for (final curso in _cursos) {
      if (curso.id == id) return curso;
    }
    return null;
  }

  /// Compara sem diferenciar maiúsculas de minúsculas. [ignorarId] serve para
  /// o curso que está sendo editado não conflitar com ele mesmo.
  static bool nomeJaExiste(String nome, {String? ignorarId}) {
    final procurado = nome.trim().toLowerCase();
    return _cursos.any(
      (curso) =>
          curso.id != ignorarId && curso.nome.trim().toLowerCase() == procurado,
    );
  }

  static Curso adicionar(String nome) {
    final curso = Curso(id: '${_proximoId++}', nome: nome.trim());
    _cursos.add(curso);
    return curso;
  }

  static void editar(String id, String nome) {
    _atualizar(id, (curso) => curso.copyWith(nome: nome.trim()));
  }

  static void definirAtivo(String id, bool ativo) {
    _atualizar(id, (curso) => curso.copyWith(ativo: ativo));
  }

  static void _atualizar(String id, Curso Function(Curso) mudar) {
    final indice = _cursos.indexWhere((curso) => curso.id == id);
    if (indice == -1) return;
    _cursos[indice] = mudar(_cursos[indice]);
  }
}
