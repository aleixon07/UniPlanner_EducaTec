import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/horario.dart';
import '../model/reserva.dart';

/// Conflitos de horário: um professor ou um aluno não pode estar em duas aulas
/// no mesmo bloco (dia da semana + turno). A grade trabalha com turnos, então o
/// bloco inteiro conta como ocupado.
///
/// Consultas comuns, não transações: o SDK do Firestore para celular não aceita
/// consultas dentro de transações. Por isso, dois cadastros feitos exatamente
/// ao mesmo tempo podem passar juntos. Para uma escola, o risco é mínimo.
class Conflitos {
  Conflitos._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Aula de outra disciplina, dada pelo [professorId], no mesmo [dia] e
  /// [turno]. `null` se estiver livre. [ignorarDisciplinaId] é a disciplina
  /// que está sendo mexida (não conta como conflito consigo mesma).
  static Future<Horario?> doProfessor(
    String professorId,
    DiaSemana dia,
    Turno turno, {
    String? ignorarDisciplinaId,
  }) async {
    final disciplinas = await _db
        .collection('disciplinas')
        .where('professorIds', arrayContains: professorId)
        .get();
    final ids = [
      for (final d in disciplinas.docs)
        if (d.id != ignorarDisciplinaId) d.id,
    ];
    return _noBloco(ids, dia, turno);
  }

  /// Aula de alguma disciplina em que o [alunoId] está matriculado, no mesmo
  /// [dia] e [turno]. `null` se estiver livre.
  static Future<Horario?> doAluno(
    String alunoId,
    DiaSemana dia,
    Turno turno, {
    String? ignorarDisciplinaId,
  }) async {
    final matriculas = await _db
        .collection('matriculas')
        .where('alunoId', isEqualTo: alunoId)
        .get();
    final ids = <String>[];
    for (final m in matriculas.docs) {
      final disciplinaId = m.data()['disciplinaId'];
      if (disciplinaId is String && disciplinaId != ignorarDisciplinaId) {
        ids.add(disciplinaId);
      }
    }
    return _noBloco(ids, dia, turno);
  }

  /// Horários fixos já gravados para a disciplina (usado ao vincular um
  /// professor: ele precisa estar livre em todos os blocos dela).
  static Future<List<Horario>> horariosDaDisciplina(String disciplinaId) async {
    final r = await _db
        .collection('horarios')
        .where('disciplinaId', isEqualTo: disciplinaId)
        .get();
    return [for (final doc in r.docs) ?Horario.fromMap(doc.id, doc.data())];
  }

  static Future<Horario?> _noBloco(
    List<String> disciplinaIds,
    DiaSemana dia,
    Turno turno,
  ) async {
    if (disciplinaIds.isEmpty) return null;
    // whereIn aceita até 30 valores; ninguém aqui dá mais disciplinas que isso.
    final ids = disciplinaIds.take(30).toList();
    final r = await _db
        .collection('horarios')
        .where('disciplinaId', whereIn: ids)
        .get();
    for (final doc in r.docs) {
      final h = Horario.fromMap(doc.id, doc.data());
      if (h != null && h.dia == dia && h.turno == turno) return h;
    }
    return null;
  }

  /// Ex.: "segunda-feira (manhã)", para as mensagens de erro.
  static String descrever(DiaSemana dia, Turno turno) =>
      '${dia.rotulo.toLowerCase()} (${turno.rotulo.toLowerCase()})';
}
