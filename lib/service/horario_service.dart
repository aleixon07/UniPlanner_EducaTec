import 'package:cloud_firestore/cloud_firestore.dart';

import 'conflitos.dart';
import '../model/horario.dart';
import '../model/reserva.dart';
import '../model/sala.dart';

/// Erro de horário já traduzido para mostrar na tela.
class ErroHorario implements Exception {
  final String mensagem;
  const ErroHorario(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Grade de horários: as aulas fixas de cada semestre.
abstract class HorarioService {
  static HorarioService instancia = FirebaseHorarioService();

  /// Aulas fixas de um semestre (turma), sempre atualizadas.
  Stream<List<Horario>> doSemestre(String semestreId);

  /// Aulas fixas que usam a sala. O calendário de reserva usa para mostrar os
  /// dias em que a sala já tem aula.
  Stream<List<Horario>> daSala(Sala sala);

  /// Aulas fixas das disciplinas (as de um professor, ou as que um aluno
  /// cursa). Usado em "Aulas do Dia".
  Stream<List<Horario>> dasDisciplinas(List<String> disciplinaIds);

  /// Grava a aula no dia e turno (substitui a que estiver lá). Lança
  /// [ErroHorario] se a sala já tiver outra aula fixa nesse dia e turno.
  Future<void> salvar(Horario horario);

  /// Tira a aula da grade. Lança [ErroHorario].
  Future<void> excluir(Horario horario);

  /// Aula fixa que ocupa a sala no dia e turno, ou `null`. Usado para impedir
  /// reserva por cima de uma aula da grade.
  Future<Horario?> ocupando(Sala sala, DiaSemana dia, Turno turno);
}

class FirebaseHorarioService implements HorarioService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('horarios');

  List<Horario> _converter(QuerySnapshot<Map<String, dynamic>> r) => [
    for (final doc in r.docs) ?Horario.fromMap(doc.id, doc.data()),
  ];

  @override
  Stream<List<Horario>> doSemestre(String semestreId) => _colecao
      .where('semestreId', isEqualTo: semestreId)
      .snapshots()
      .map(_converter);

  @override
  Stream<List<Horario>> daSala(Sala sala) => _colecao
      .where('salaId', isEqualTo: Reserva.salaIdDe(sala))
      .snapshots()
      .map(_converter);

  @override
  Stream<List<Horario>> dasDisciplinas(List<String> disciplinaIds) {
    if (disciplinaIds.isEmpty) return Stream.value(const []);
    // O Firestore aceita até 30 valores num whereIn. Mais que isso numa pessoa
    // só (30 disciplinas ao mesmo tempo) não é um caso real aqui.
    final ids = disciplinaIds.take(30).toList();
    return _colecao
        .where('disciplinaId', whereIn: ids)
        .snapshots()
        .map(_converter);
  }

  @override
  Future<Horario?> ocupando(Sala sala, DiaSemana dia, Turno turno) async {
    final r = await _colecao
        .where('salaId', isEqualTo: Reserva.salaIdDe(sala))
        .get();
    return _converter(r)
        .where((h) => h.dia == dia && h.turno == turno)
        .firstOrNull;
  }

  @override
  Future<void> salvar(Horario horario) async {
    final id = Horario.idPara(horario.semestreId, horario.dia, horario.turno);
    try {
      final conflito = await ocupando(horario.sala, horario.dia, horario.turno);
      if (conflito != null && conflito.id != id) {
        throw ErroHorario(
          '${horario.sala.rotuloCurto} ${horario.sala.numero} já tem aula de '
          '"${conflito.disciplinaNome}" na ${horario.dia.rotulo.toLowerCase()} '
          '(${horario.turno.rotulo.toLowerCase()}).',
        );
      }

      // Cada professor da disciplina precisa estar livre neste bloco.
      final disciplina = await FirebaseFirestore.instance
          .collection('disciplinas')
          .doc(horario.disciplinaId)
          .get();
      final professores = [
        ...?(disciplina.data()?['professorIds'] as List?)?.whereType<String>(),
      ];
      for (final professorId in professores) {
        final outra = await Conflitos.doProfessor(
          professorId,
          horario.dia,
          horario.turno,
          ignorarDisciplinaId: horario.disciplinaId,
        );
        if (outra != null) {
          throw ErroHorario(
            'Um dos professores desta disciplina já dá "${outra.disciplinaNome}" '
            'na ${Conflitos.descrever(horario.dia, horario.turno)}.',
          );
        }
      }

      await _colecao.doc(id).set({
        ...horario.toMap(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroHorario(_traduzir(e.code));
    }
  }

  @override
  Future<void> excluir(Horario horario) async {
    try {
      await _colecao.doc(horario.id).delete();
    } on FirebaseException catch (e) {
      throw ErroHorario(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) => switch (codigo) {
    'permission-denied' =>
      'Sem permissão para salvar. Verifique as regras do Firestore.',
    'unavailable' => 'Sem conexão. Verifique sua internet.',
    _ => 'Não foi possível salvar o horário ($codigo).',
  };
}
