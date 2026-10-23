import 'package:flutter/material.dart';

import 'sala.dart';

enum DiaSemana { segunda, terca, quarta, quinta, sexta, sabado }

extension DiaSemanaInfo on DiaSemana {
  String get rotulo => switch (this) {
    DiaSemana.segunda => 'Segunda',
    DiaSemana.terca => 'Terça',
    DiaSemana.quarta => 'Quarta',
    DiaSemana.quinta => 'Quinta',
    DiaSemana.sexta => 'Sexta',
    DiaSemana.sabado => 'Sábado',
  };
}

/// Um encontro semanal da disciplina. Ex.: segunda, das 19h às 20h30.
class HorarioAula {
  final DiaSemana dia;
  final TimeOfDay inicio;
  final TimeOfDay fim;

  const HorarioAula({
    required this.dia,
    required this.inicio,
    required this.fim,
  });
}

/// Disciplina ofertada em um semestre de um curso.
class Disciplina {
  final String nome;
  final String professor;
  final Sala sala;
  final List<HorarioAula> horarios;

  const Disciplina({
    required this.nome,
    required this.professor,
    required this.sala,
    required this.horarios,
  });
}
