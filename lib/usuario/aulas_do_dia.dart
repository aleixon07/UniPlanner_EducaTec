import 'package:flutter/material.dart';

import '../model/horario.dart';
import '../model/reserva.dart';
import '../model/sala.dart';
import '../service/agenda.dart';
import '../service/horario_service.dart';
import '../service/reserva_service.dart';
import '../service/sessao.dart';
import '../service/streams.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _laranja = Color(0xFFF2994A);

/// Uma aula como aparece em "Aulas do Dia": da grade (fixa) ou de uma reserva.
class AulaDoDia {
  final Sala sala;
  final String disciplina;
  final Turno turno;

  /// `true` se veio de uma reserva (aula extra ou troca de sala).
  final bool reserva;

  const AulaDoDia({
    required this.sala,
    required this.disciplina,
    required this.turno,
    required this.reserva,
  });
}

/// Monta as aulas do [dia]: as aulas fixas da grade naquele dia da semana, mais
/// as reservas do dia. Se uma reserva é da mesma disciplina e turno de uma
/// aula fixa, ela substitui a fixa (é a troca de sala daquele dia).
List<AulaDoDia> montarAulasDoDia(
  DateTime dia,
  List<Horario> fixas,
  List<Reserva> reservas,
) {
  final diaSemana = DiaSemanaInfo.de(dia);
  final doDia = reservas.where((r) => r.ehDoDia(dia)).toList();

  final aulas = <AulaDoDia>[
    for (final h in fixas)
      if (h.dia == diaSemana &&
          !doDia.any(
            (r) => r.disciplinaId == h.disciplinaId && r.turno == h.turno,
          ))
        AulaDoDia(
          sala: h.sala,
          disciplina: h.disciplinaNome,
          turno: h.turno,
          reserva: false,
        ),
    for (final r in doDia)
      AulaDoDia(
        sala: r.sala,
        disciplina: r.disciplina,
        turno: r.turno,
        reserva: true,
      ),
  ];
  aulas.sort((a, b) => a.turno.index.compareTo(b.turno.index));
  return aulas;
}

/// "Aulas do Dia" da tela principal, para o [dia] escolhido no calendário.
///
/// - Professor: a grade das disciplinas dele, mais as reservas.
/// - Aluno: a grade das disciplinas em que está matriculado, mais as reservas
///   delas (feitas pelo professor) e as dele.
/// - Administrador: só as reservas que ele fez.
class AulasDoDia extends StatefulWidget {
  final DateTime dia;

  const AulasDoDia({super.key, required this.dia});

  @override
  State<AulasDoDia> createState() => _AulasDoDiaState();
}

class _AulasDoDiaState extends State<AulasDoDia> {
  // Criados uma vez só: trocar o dia no calendário só refiltra, sem abrir
  // outras conexões com o Firestore.
  late final Stream<List<String>> _ids = disciplinaIdsDe(Sessao.usuario)
      .asBroadcastStream();
  late final Stream<List<Horario>> _fixas = trocarPara(
    _ids,
    HorarioService.instancia.dasDisciplinas,
  );
  late final Stream<List<Reserva>> _dasDisciplinas = trocarPara(
    _ids,
    ReservaService.instancia.dasDisciplinas,
  );
  late final Stream<List<Reserva>> _minhas = ReservaService.instancia
      .minhasReservas();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Horario>>(
      stream: _fixas,
      builder: (context, snapFixas) {
        return StreamBuilder<List<Reserva>>(
          stream: _dasDisciplinas,
          builder: (context, snapDisciplinas) {
            return StreamBuilder<List<Reserva>>(
              stream: _minhas,
              builder: (context, snapMinhas) {
                if (snapFixas.hasError ||
                    snapDisciplinas.hasError ||
                    snapMinhas.hasError) {
                  return const _Mensagem('Não foi possível carregar as aulas.');
                }

                final fixas = snapFixas.data;
                final dasDisciplinas = snapDisciplinas.data;
                final minhas = snapMinhas.data;
                if (fixas == null || dasDisciplinas == null || minhas == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // A mesma reserva pode vir nas duas listas (minha e da minha
                // disciplina): junta sem repetir.
                final reservas = {
                  for (final r in [...dasDisciplinas, ...minhas]) r.id: r,
                }.values.toList();

                final aulas = montarAulasDoDia(widget.dia, fixas, reservas);
                if (aulas.isEmpty) {
                  return const _Mensagem('Nenhuma aula neste dia.');
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: aulas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _CardAula(aula: aulas[i]),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CardAula extends StatelessWidget {
  final AulaDoDia aula;

  const _CardAula({required this.aula});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // SALA
          Container(
            width: 75,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE3E3E3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  aula.sala.rotuloCurto,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aula.sala.numero,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _azulEscuro,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // DISCIPLINA E HORÁRIO
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aula.disciplina,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _azulEscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${aula.turno.rotulo} | ${aula.turno.horario}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Aula que veio de reserva (extra ou troca de sala).
          if (aula.reserva)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _laranja,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Reserva',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final String texto;

  const _Mensagem(this.texto);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    );
  }
}
