import 'reserva.dart';
import 'sala.dart';

/// Dia da semana de uma aula fixa. A ordem segue o `DateTime.weekday` do Dart
/// (segunda = 1), para converter uma data com [DiaSemanaInfo.de].
enum DiaSemana { segunda, terca, quarta, quinta, sexta, sabado }

extension DiaSemanaInfo on DiaSemana {
  String get rotulo => switch (this) {
    DiaSemana.segunda => 'Segunda-feira',
    DiaSemana.terca => 'Terça-feira',
    DiaSemana.quarta => 'Quarta-feira',
    DiaSemana.quinta => 'Quinta-feira',
    DiaSemana.sexta => 'Sexta-feira',
    DiaSemana.sabado => 'Sábado',
  };

  /// Dia da semana de uma data, ou `null` no domingo (sem aulas).
  static DiaSemana? de(DateTime data) => data.weekday == DateTime.sunday
      ? null
      : DiaSemana.values[data.weekday - 1];
}

/// Aula fixa da grade de horários: uma disciplina, num dia da semana e turno,
/// numa sala. Repete toda semana; as reservas são as exceções.
///
/// Fica na coleção `horarios`. O id é [idPara] (semestre + dia + turno): numa
/// mesma turma (semestre), cada dia e turno tem no máximo uma aula.
class Horario {
  final String id;
  final String cursoId;
  final String semestreId;
  final String disciplinaId;

  /// Nome copiado para "Aulas do Dia" não precisar buscar a disciplina.
  /// Renomear a disciplina atualiza esta cópia.
  final String disciplinaNome;

  final DiaSemana dia;
  final Turno turno;

  /// Sala copiada (número, tipo, andar), como nas reservas.
  final Sala sala;

  const Horario({
    this.id = '',
    required this.cursoId,
    required this.semestreId,
    required this.disciplinaId,
    required this.disciplinaNome,
    required this.dia,
    required this.turno,
    required this.sala,
  });

  /// Ex.: `abc123_segunda_manha`
  static String idPara(String semestreId, DiaSemana dia, Turno turno) =>
      '${semestreId}_${dia.name}_${turno.name}';

  Map<String, Object?> toMap() => {
    'cursoId': cursoId,
    'semestreId': semestreId,
    'disciplinaId': disciplinaId,
    'disciplinaNome': disciplinaNome,
    'dia': dia.name,
    'turno': turno.name,
    'salaId': Reserva.salaIdDe(sala),
    'salaNumero': sala.numero,
    'salaTipo': sala.tipo.name,
    'salaAndar': sala.andar,
  };

  static Horario? fromMap(String id, Map<String, dynamic> dados) {
    final dia = DiaSemana.values.where((d) => d.name == dados['dia']);
    final turno = Turno.values.where((t) => t.name == dados['turno']);
    if (dia.isEmpty || turno.isEmpty) return null;

    return Horario(
      id: id,
      cursoId: (dados['cursoId'] as String?) ?? '',
      semestreId: (dados['semestreId'] as String?) ?? '',
      disciplinaId: (dados['disciplinaId'] as String?) ?? '',
      disciplinaNome: (dados['disciplinaNome'] as String?) ?? '',
      dia: dia.first,
      turno: turno.first,
      sala: Sala(
        id: (dados['salaId'] as String?) ?? '',
        numero: (dados['salaNumero'] as String?) ?? '',
        tipo: TipoSala.values.firstWhere(
          (t) => t.name == dados['salaTipo'],
          orElse: () => TipoSala.sala,
        ),
        andar: (dados['salaAndar'] as String?) ?? '',
      ),
    );
  }
}
