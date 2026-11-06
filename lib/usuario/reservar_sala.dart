import 'package:flutter/material.dart';

import '../model/sala.dart';
import '../service/sala_service.dart';
import '../sidebar.dart';
import 'widgets_sala.dart';

const Color _vermelho = Color(0xFFE23B3B);

/// Tela do usuário: escolhe um ambiente cadastrado e faz a reserva.
/// As salas vêm do Firestore (cadastradas pelo administrador).
class ReservarSala extends StatefulWidget {
  const ReservarSala({super.key});

  @override
  State<ReservarSala> createState() => _ReservarSalaState();
}

class _ReservarSalaState extends State<ReservarSala> {
  // Criado uma vez só, para não abrir uma nova conexão a cada rebuild.
  late final Stream<List<Sala>> _salas = SalaService.instancia.listar();

  FiltroSala _filtro = FiltroSala.todos;

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  FiltrosSala(
                    selecionado: _filtro,
                    onChanged: (filtro) => setState(() => _filtro = filtro),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: StreamBuilder<List<Sala>>(
                      stream: _salas,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const MensagemSalas(
                            'Não foi possível carregar as salas. '
                            'Verifique a conexão.',
                            cor: _vermelho,
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.data!.isEmpty) {
                          return const MensagemSalas(
                            'Nenhuma sala cadastrada ainda.',
                          );
                        }

                        final visiveis = filtrarSalas(snapshot.data!, _filtro);
                        if (visiveis.isEmpty) {
                          return const MensagemSalas(
                            'Nenhum ambiente neste filtro.',
                          );
                        }

                        return GradeSalas(
                          salas: visiveis,
                          onTap: (sala) => reservarSala(context, sala),
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
          const Expanded(flex: 4, child: PainelReservas()),
        ],
      ),
    );
  }
}
