import '../model/disciplina.dart';
import '../model/usuario.dart';
import 'disciplina_service.dart';
import 'matricula_service.dart';
import 'streams.dart';

/// Ids das disciplinas "da pessoa", que alimentam "Aulas do Dia" e a reserva:
/// - professor: as disciplinas em que ele dá aula;
/// - aluno: as disciplinas em que está matriculado;
/// - administrador: nenhuma (ele não tem aulas próprias).
Stream<List<String>> disciplinaIdsDe(Usuario? usuario) {
  if (usuario == null) return Stream.value(const []);
  return switch (usuario.perfil) {
    PerfilUsuario.professor =>
      DisciplinaService.instancia
          .doProfessor(usuario.id)
          .map((lista) => [for (final d in lista) d.id]),
    PerfilUsuario.aluno =>
      MatriculaService.instancia
          .doAluno(usuario.id)
          .map((lista) => [for (final m in lista) m.disciplinaId]),
    PerfilUsuario.administrador => Stream.value(const []),
  };
}

/// Disciplinas que a pessoa pode usar numa reserva: as dela (veja
/// [disciplinaIdsDe]); o administrador pode reservar para qualquer uma.
Stream<List<Disciplina>> disciplinasParaReserva(Usuario? usuario) {
  if (usuario == null) return Stream.value(const []);
  final servico = DisciplinaService.instancia;
  return switch (usuario.perfil) {
    PerfilUsuario.administrador => servico.todas(),
    PerfilUsuario.professor => servico.doProfessor(usuario.id),
    PerfilUsuario.aluno => trocarPara(disciplinaIdsDe(usuario), servico.porIds),
  };
}
