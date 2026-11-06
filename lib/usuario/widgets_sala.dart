import 'package:flutter/material.dart';

import '../model/reserva.dart';
import '../model/sala.dart';
import '../service/formatador_data.dart';
import '../service/reserva_service.dart';
import 'dialog_reserva.dart';

// Peças usadas tanto na tela de reserva do usuário (ReservarSala) quanto no
// gerenciamento de salas do administrador (GerenciarSalas).

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(fontFamily: 'NunitoSans'),
        ),
      ),
    );
}

enum FiltroSala { todos, salas, laboratorios }

List<Sala> filtrarSalas(List<Sala> salas, FiltroSala filtro) {
  switch (filtro) {
    case FiltroSala.todos:
      return salas;
    case FiltroSala.salas:
      return salas.where((s) => !s.ehLaboratorio).toList();
    case FiltroSala.laboratorios:
      return salas.where((s) => s.ehLaboratorio).toList();
  }
}

/// Fluxo completo: modal de reserva -> alerta de confirmação -> salva no
/// Firestore -> sucesso. O painel "Minhas Reservas" se atualiza sozinho.
Future<void> reservarSala(BuildContext context, Sala sala) async {
  final reserva = await showDialog<Reserva>(
    context: context,
    builder: (context) => DialogReserva(sala: sala),
  );

  if (reserva == null || !context.mounted) return;

  final confirmou = await confirmarReserva(context, reserva);
  if (!confirmou || !context.mounted) return;

  try {
    await ReservaService.instancia.reservar(reserva);
  } on ErroReserva catch (e) {
    if (context.mounted) _avisar(context, e.mensagem);
    return;
  } catch (_) {
    if (context.mounted) {
      _avisar(context, 'Erro inesperado ao reservar. Tente novamente.');
    }
    return;
  }

  if (!context.mounted) return;
  await avisarReservaConcluida(context, reserva);
}

/// Pergunta se quer mesmo cancelar e, se sim, apaga a reserva.
Future<void> cancelarReserva(BuildContext context, Reserva reserva) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Cancelar reserva?',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _azulEscuro,
        ),
      ),
      content: Text(
        '${reserva.sala.rotuloCurto} ${reserva.sala.numero} — '
        '${reserva.disciplina}\n'
        '${formatarDataCurta(reserva.data)}, ${reserva.turno.rotulo} '
        '(${reserva.turno.horario})',
        style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Voltar',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: _vermelho,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cancelar reserva',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmou != true || !context.mounted) return;

  try {
    await ReservaService.instancia.cancelar(reserva);
    if (context.mounted) _avisar(context, 'Reserva cancelada.');
  } on ErroReserva catch (e) {
    if (context.mounted) _avisar(context, e.mensagem);
  }
}

// ================================================================
// FILTROS: Todos / Salas / Lab.
// ================================================================
class FiltrosSala extends StatelessWidget {
  final FiltroSala selecionado;
  final ValueChanged<FiltroSala> onChanged;

  const FiltrosSala({
    super.key,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const rotulos = {
      FiltroSala.todos: 'Todos',
      FiltroSala.salas: 'Salas',
      FiltroSala.laboratorios: 'Lab.',
    };

    return Row(
      children: [
        for (final filtro in FiltroSala.values) ...[
          Expanded(
            child: _Chip(
              texto: rotulos[filtro]!,
              selecionado: selecionado == filtro,
              onTap: () => onChanged(filtro),
            ),
          ),
          if (filtro != FiltroSala.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

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
// GRADE DE AMBIENTES
// ================================================================
class GradeSalas extends StatelessWidget {
  final List<Sala> salas;
  final ValueChanged<Sala> onTap;

  /// Opcional: o administrador segura o botão para remover a sala.
  final ValueChanged<Sala>? onLongPress;

  const GradeSalas({
    super.key,
    required this.salas,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          onTap: () => onTap(sala),
          onLongPress: onLongPress == null ? null : () => onLongPress!(sala),
        );
      },
    );
  }
}

class _BotaoSala extends StatelessWidget {
  final Sala sala;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BotaoSala({required this.sala, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
    );
  }
}

// ================================================================
// PAINEL "MINHAS RESERVAS" (fundo azul escuro)
// ================================================================
class PainelReservas extends StatefulWidget {
  const PainelReservas({super.key});

  @override
  State<PainelReservas> createState() => _PainelReservasState();
}

class _PainelReservasState extends State<PainelReservas> {
  // Criado uma vez só, para não abrir uma nova conexão a cada rebuild.
  late final Stream<List<Reserva>> _reservas = ReservaService.instancia
      .minhasReservas();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: StreamBuilder<List<Reserva>>(
              stream: _reservas,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const MensagemSalas(
                    'Não foi possível carregar suas reservas.',
                    cor: Colors.white70,
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final reservas = snapshot.data!;
                if (reservas.isEmpty) {
                  return const MensagemSalas(
                    'Você ainda não tem reservas.',
                    cor: Colors.white70,
                  );
                }

                return ListView.separated(
                  itemCount: reservas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  // O context usado no cancelamento é o do StreamBuilder, e
                  // não o do item: o item some da lista quando a reserva é
                  // apagada, e o aviso de "cancelada" precisa de um context
                  // que continue vivo.
                  itemBuilder: (_, index) {
                    final reserva = reservas[index];
                    return _CardReserva(
                      reserva: reserva,
                      onCancelar: () => cancelarReserva(context, reserva),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de reserva que desliza para a esquerda e revela, por baixo, o botão
/// vermelho de cancelar. Arrastar de volta (ou tocar no card) fecha.
class _CardReserva extends StatefulWidget {
  final Reserva reserva;
  final VoidCallback onCancelar;

  const _CardReserva({required this.reserva, required this.onCancelar});

  @override
  State<_CardReserva> createState() => _CardReservaState();
}

class _CardReservaState extends State<_CardReserva> {
  /// Quanto o card anda para a esquerda quando aberto.
  static const double _larguraBotao = 64;

  /// 0 = fechado, -[_larguraBotao] = aberto.
  double _deslocamento = 0;

  /// Durante o arrasto o card acompanha o dedo sem animação; ao soltar, ele
  /// anima até ficar aberto ou fechado.
  bool _arrastando = false;

  bool get _aberto => _deslocamento != 0;

  void _arrastar(DragUpdateDetails detalhes) {
    setState(() {
      _arrastando = true;
      _deslocamento = (_deslocamento + (detalhes.primaryDelta ?? 0)).clamp(
        -_larguraBotao,
        0.0,
      );
    });
  }

  void _soltar(DragEndDetails detalhes) {
    final velocidade = detalhes.primaryVelocity ?? 0;
    // Um "peteleco" rápido decide sozinho; devagar, vale a posição.
    final abrir =
        velocidade < -300 ||
        (velocidade <= 300 && _deslocamento < -_larguraBotao / 2);

    setState(() {
      _arrastando = false;
      _deslocamento = abrir ? -_larguraBotao : 0;
    });
  }

  void _fechar() => setState(() => _deslocamento = 0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // FUNDO VERMELHO COM O BOTÃO (só aparece quando o card se mexe, para
        // não vazar vermelho pelos cantos arredondados quando está fechado)
        if (_aberto || _arrastando)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: _vermelho,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: _larguraBotao,
                child: IconButton(
                  tooltip: 'Cancelar reserva',
                  icon: const Icon(
                    Icons.highlight_off,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    _fechar();
                    widget.onCancelar();
                  },
                ),
              ),
            ),
          ),

        // CARD
        GestureDetector(
          onHorizontalDragUpdate: _arrastar,
          onHorizontalDragEnd: _soltar,
          onTap: _aberto ? _fechar : null,
          child: AnimatedContainer(
            duration: _arrastando
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_deslocamento, 0, 0),
            child: _conteudo(widget.reserva),
          ),
        ),
      ],
    );
  }

  Widget _conteudo(Reserva reserva) {
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

            // Linha separando o ambiente das informações.
            Container(width: 1, color: const Color(0xFF9E9E9E)),

            const SizedBox(width: 12),

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

// ================================================================
// MENSAGEM NO LUGAR DA GRADE (vazio, erro...)
// ================================================================
class MensagemSalas extends StatelessWidget {
  final String texto;
  final Color cor;

  const MensagemSalas(
    this.texto, {
    super.key,
    this.cor = const Color(0xFF7A7A7A),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: cor),
        ),
      ),
    );
  }
}
