import 'package:flutter/material.dart';

import '../model/reserva.dart';
import '../model/sala.dart';
import '../service/formatador_data.dart';
import '../service/reserva_service.dart';
import '../sidebar.dart';
import 'dialog_reserva.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);

enum _Filtro { todos, salas, laboratorios }

class ReservarSala extends StatefulWidget {
  const ReservarSala({super.key});

  @override
  State<ReservarSala> createState() => _ReservarSalaState();
}

class _ReservarSalaState extends State<ReservarSala> {
  _Filtro _filtro = _Filtro.todos;

  List<Sala> get _salasVisiveis {
    switch (_filtro) {
      case _Filtro.todos:
        return ReservaService.salas;
      case _Filtro.salas:
        return ReservaService.salas.where((s) => !s.ehLaboratorio).toList();
      case _Filtro.laboratorios:
        return ReservaService.salas.where((s) => s.ehLaboratorio).toList();
    }
  }

  /// Fluxo completo: modal de reserva -> alerta de confirmação -> sucesso.
  Future<void> _reservar(Sala sala) async {
    final reserva = await showDialog<Reserva>(
      context: context,
      builder: (context) => DialogReserva(sala: sala),
    );

    if (reserva == null || !mounted) return;

    final confirmou = await confirmarReserva(context, reserva);
    if (!confirmou || !mounted) return;

    setState(() {
      ReservaService.adicionar(reserva);
    });

    await avisarReservaConcluida(context, reserva);
  }

  @override
  Widget build(BuildContext context) {
    final salas = _salasVisiveis;

    return Scaffold(
      appBar: const AppBarUniPlanner(),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,

      body: Column(
        children: [
          // ============================================================
          // FILTRO + GRADE DE AMBIENTES
          // ============================================================
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Chip(
                          texto: 'Todos',
                          selecionado: _filtro == _Filtro.todos,
                          onTap: () => setState(() => _filtro = _Filtro.todos),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Chip(
                          texto: 'Salas',
                          selecionado: _filtro == _Filtro.salas,
                          onTap: () => setState(() => _filtro = _Filtro.salas),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Chip(
                          texto: 'Lab.',
                          selecionado: _filtro == _Filtro.laboratorios,
                          onTap: () =>
                              setState(() => _filtro = _Filtro.laboratorios),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                          ),
                      itemCount: salas.length,
                      itemBuilder: (context, index) {
                        final sala = salas[index];
                        return _BotaoSala(
                          sala: sala,
                          onTap: () => _reservar(sala),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // MINHAS RESERVAS
          // ============================================================
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: _azulEscuro,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Text(
                    'Minhas Reservas',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ReservaService.minhasReservas.isEmpty
                        ? const Center(
                            child: Text(
                              'Você ainda não tem reservas.',
                              style: TextStyle(
                                fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: ReservaService.minhasReservas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _CardReserva(
                                reserva: ReservaService.minhasReservas[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CHIP DE FILTRO
// ================================================================
class _Chip extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback onTap;

  const _Chip({
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? _azul : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? _azul : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(
          texto,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selecionado ? Colors.white : _azulEscuro,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// BOTÃO DE UM AMBIENTE NA GRADE
// ================================================================
class _BotaoSala extends StatelessWidget {
  final Sala sala;
  final VoidCallback onTap;

  const _BotaoSala({required this.sala, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sala.ehLaboratorio)
              const Text(
                'Lab.',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            Text(
              sala.numero,
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
    );
  }
}

// ================================================================
// CARD DE UMA RESERVA
// ================================================================
class _CardReserva extends StatelessWidget {
  final Reserva reserva;

  const _CardReserva({required this.reserva});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AMBIENTE
            Container(
              width: 75,
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                    reserva.sala.rotuloCurto,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reserva.sala.numero,
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

            // INFORMAÇÕES
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reserva.disciplina,
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
                    '${formatarDataCurta(reserva.data)} | '
                    '${reserva.turno.rotulo} ${reserva.turno.horario}',
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

            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
