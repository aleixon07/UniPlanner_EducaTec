import 'package:cloud_firestore/cloud_firestore.dart';

/// Matrícula de um aluno numa disciplina.
///
/// Fica na coleção `matriculas`. O id é [idPara] (aluno + disciplina): o mesmo
/// aluno não fica matriculado duas vezes na mesma disciplina.
class Matricula {
  final String id;
  final String alunoId;
  final String disciplinaId;
  final String cursoId;
  final String semestreId;

  const Matricula({
    this.id = '',
    required this.alunoId,
    required this.disciplinaId,
    required this.cursoId,
    required this.semestreId,
  });

  static String idPara(String alunoId, String disciplinaId) =>
      '${alunoId}_$disciplinaId';

  Map<String, Object?> toMap() => {
    'alunoId': alunoId,
    'disciplinaId': disciplinaId,
    'cursoId': cursoId,
    'semestreId': semestreId,
  };

  factory Matricula.fromMap(String id, Map<String, dynamic> dados) {
    return Matricula(
      id: id,
      alunoId: (dados['alunoId'] as String?) ?? '',
      disciplinaId: (dados['disciplinaId'] as String?) ?? '',
      cursoId: (dados['cursoId'] as String?) ?? '',
      semestreId: (dados['semestreId'] as String?) ?? '',
    );
  }
}

/// Período em que os alunos podem se matricular sozinhos, e em quais
/// semestres (por número: 1, 3, 5, 7 num período; 2, 4, 6, 8 no outro).
///
/// Fica no documento `config/matricula`. O administrador matricula a qualquer
/// momento; o período só limita o aluno.
class PeriodoMatricula {
  /// Primeiro e último dia do período (os dois inclusos). `null` = sem período.
  final DateTime? inicio;
  final DateTime? fim;
  final List<int> semestres;

  const PeriodoMatricula({this.inicio, this.fim, this.semestres = const []});

  static const fechado = PeriodoMatricula();

  /// Aberto se hoje está entre [inicio] e [fim] e há semestre liberado.
  bool abertoEm(DateTime agora) {
    final i = inicio;
    final f = fim;
    if (i == null || f == null || semestres.isEmpty) return false;
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return !hoje.isBefore(i) && !hoje.isAfter(f);
  }

  bool liberado(int numeroSemestre) => semestres.contains(numeroSemestre);

  /// As datas vão como Timestamp: as regras do Firestore comparam com o
  /// horário do servidor (`request.time`). O fim é gravado como o último
  /// instante do dia, para o último dia valer inteiro.
  Map<String, Object?> toMap() => {
    'inicio': inicio == null ? null : Timestamp.fromDate(inicio!),
    'fim': fim == null
        ? null
        : Timestamp.fromDate(
            DateTime(fim!.year, fim!.month, fim!.day, 23, 59, 59),
          ),
    'semestres': [...semestres]..sort(),
  };

  factory PeriodoMatricula.fromMap(Map<String, dynamic>? dados) {
    if (dados == null) return fechado;
    DateTime? dia(Object? v) {
      if (v is! Timestamp) return null;
      final d = v.toDate();
      return DateTime(d.year, d.month, d.day);
    }

    return PeriodoMatricula(
      inicio: dia(dados['inicio']),
      fim: dia(dados['fim']),
      semestres: [
        for (final n in (dados['semestres'] as List?) ?? const [])
          if (n is num) n.toInt(),
      ],
    );
  }
}
