import 'sala.dart';

enum Turno { manha, tarde, noite }

extension TurnoInfo on Turno {
  String get rotulo {
    switch (this) {
      case Turno.manha:
        return 'Manhã';
      case Turno.tarde:
        return 'Tarde';
      case Turno.noite:
        return 'Noite';
    }
  }

  String get horario {
    switch (this) {
      case Turno.manha:
        return '07:30 - 11:30';
      case Turno.tarde:
        return '13:30 - 17:30';
      case Turno.noite:
        return '19:00 - 22:30';
    }
  }
}

/// Reserva de um ambiente para uma disciplina, em um turno e dia.
class Reserva {
  final Sala sala;
  final String disciplina;
  final Turno turno;
  final DateTime data;

  const Reserva({
    required this.sala,
    required this.disciplina,
    required this.turno,
    required this.data,
  });

  bool ehDoDia(DateTime dia) {
    return data.year == dia.year &&
        data.month == dia.month &&
        data.day == dia.day;
  }
}
