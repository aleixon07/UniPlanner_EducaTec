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
///
/// Fica na coleção `reservas` do Firestore. O [id] do documento é montado com
/// [idPara] (sala + turno + dia): como só pode existir um documento com esse
/// id, a mesma sala nunca fica reservada duas vezes no mesmo turno.
class Reserva {
  final String id;
  final Sala sala;
  final String disciplina;
  final Turno turno;

  /// Só o dia importa; a hora fica sempre em 00:00.
  final DateTime data;

  /// `uid` de quem reservou (Firebase Authentication).
  final String usuarioId;

  const Reserva({
    this.id = '',
    required this.sala,
    required this.disciplina,
    required this.turno,
    required this.data,
    this.usuarioId = '',
  });

  bool ehDoDia(DateTime dia) {
    return data.year == dia.year &&
        data.month == dia.month &&
        data.day == dia.day;
  }

  /// Dia no formato `2026-11-06`. É texto, e não Timestamp, para não depender
  /// de fuso horário: a reserva é de um dia, não de um instante.
  static String chaveDia(DateTime dia) {
    final m = dia.month.toString().padLeft(2, '0');
    final d = dia.day.toString().padLeft(2, '0');
    return '${dia.year}-$m-$d';
  }

  static DateTime? _lerDia(Object? valor) {
    if (valor is! String) return null;
    final partes = valor.split('-');
    if (partes.length != 3) return null;
    final ano = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final dia = int.tryParse(partes[2]);
    if (ano == null || mes == null || dia == null) return null;
    return DateTime(ano, mes, dia);
  }

  /// Id da sala, igual ao do documento na coleção `salas`.
  static String salaIdDe(Sala sala) => Sala.idPara(sala.numero, sala.tipo);

  /// Id do documento. Ex.: `sala-308_manha_2026-11-06`
  static String idPara(Sala sala, Turno turno, DateTime dia) =>
      '${salaIdDe(sala)}_${turno.name}_${chaveDia(dia)}';

  /// A sala vai copiada junto (número, tipo, andar) para a lista de reservas
  /// não precisar buscar a sala de novo — e continuar legível mesmo se a sala
  /// for removida depois.
  Map<String, Object?> toMap() => {
    'salaId': salaIdDe(sala),
    'salaNumero': sala.numero,
    'salaTipo': sala.tipo.name,
    'salaAndar': sala.andar,
    'disciplina': disciplina,
    'turno': turno.name,
    'dia': chaveDia(data),
    'usuarioId': usuarioId,
  };

  /// Devolve `null` se o documento estiver incompleto, para um dado estragado
  /// não derrubar a tela inteira.
  static Reserva? fromMap(String id, Map<String, dynamic> dados) {
    final dia = _lerDia(dados['dia']);
    if (dia == null) return null;

    return Reserva(
      id: id,
      sala: Sala(
        id: (dados['salaId'] as String?) ?? '',
        numero: (dados['salaNumero'] as String?) ?? '',
        tipo: TipoSala.values.firstWhere(
          (t) => t.name == dados['salaTipo'],
          orElse: () => TipoSala.sala,
        ),
        andar: (dados['salaAndar'] as String?) ?? '',
      ),
      disciplina: (dados['disciplina'] as String?) ?? '',
      turno: Turno.values.firstWhere(
        (t) => t.name == dados['turno'],
        orElse: () => Turno.manha,
      ),
      data: dia,
      usuarioId: (dados['usuarioId'] as String?) ?? '',
    );
  }
}
