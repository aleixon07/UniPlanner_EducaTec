import '../model/reserva.dart';
import '../model/sala.dart';

/// Fonte de dados das salas e reservas.
///
/// Por enquanto tudo fica em memória, só para as telas funcionarem. Quando o
/// Firebase entrar, é este arquivo que muda — as telas continuam iguais.
class ReservaService {
  ReservaService._();

  static const List<Sala> salas = [
    Sala(numero: '301', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '302', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '303', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '304', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '305', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '306', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '307', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '308', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '309', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '310', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '311', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '312', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '301', tipo: TipoSala.laboratorio, andar: '4º Andar'),
    Sala(numero: '402', tipo: TipoSala.laboratorio, andar: '4º Andar'),
    Sala(numero: '408', tipo: TipoSala.laboratorio, andar: '4º Andar'),
    Sala(numero: '409', tipo: TipoSala.laboratorio, andar: '4º Andar'),
  ];

  static const List<String> disciplinas = [
    'Interface Humano Computador',
    'Programação T30',
    'Programação T31',
    'Banco de Dados',
    'Engenharia de Software',
  ];

  static final List<Reserva> _reservas = [
    Reserva(
      sala: salas[7],
      disciplina: 'Programação T30',
      turno: Turno.manha,
      data: DateTime.now(),
    ),
    Reserva(
      sala: salas[4],
      disciplina: 'Banco de Dados',
      turno: Turno.tarde,
      data: DateTime.now().add(const Duration(days: 2)),
    ),
  ];

  static List<Reserva> get minhasReservas => List.unmodifiable(_reservas);

  static void adicionar(Reserva reserva) => _reservas.add(reserva);

  /// Dias do mês já ocupados para a sala e o turno informados.
  ///
  /// Mistura as reservas realmente cadastradas com uma ocupação fictícia,
  /// só para o calendário do protótipo ter dias em vermelho.
  static Set<int> diasOcupados(Sala sala, Turno turno, DateTime mes) {
    final ocupados = <int>{};

    for (final reserva in _reservas) {
      final mesmaSala =
          reserva.sala.numero == sala.numero && reserva.sala.tipo == sala.tipo;
      final mesmoMes =
          reserva.data.year == mes.year && reserva.data.month == mes.month;

      if (mesmaSala && reserva.turno == turno && mesmoMes) {
        ocupados.add(reserva.data.day);
      }
    }

    // Ocupação fictícia: determinística, para não mudar a cada rebuild.
    final semente =
        int.parse(sala.numero) +
        turno.index +
        mes.month +
        (sala.ehLaboratorio ? 1 : 0);
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;

    for (var dia = 1; dia <= diasNoMes; dia++) {
      if ((dia * 7 + semente) % 5 == 0) {
        ocupados.add(dia);
      }
    }

    return ocupados;
  }
}
