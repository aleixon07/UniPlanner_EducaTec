import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';

import '../model/reserva.dart';
import '../model/sala.dart';
import '../service/formatador_data.dart';
import '../model/disciplina.dart';
import '../model/horario.dart';
import '../model/usuario.dart';
import '../service/horario_service.dart';
import '../service/reserva_service.dart';
import '../service/agenda.dart';
import '../service/sessao.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Modal de reserva: escolher disciplina, turno e dia.
///
/// Devolve a [Reserva] criada, ou `null` se o usuário cancelar.
class DialogReserva extends StatefulWidget {
  final Sala sala;

  const DialogReserva({super.key, required this.sala});

  @override
  State<DialogReserva> createState() => _DialogReservaState();
}

class _DialogReservaState extends State<DialogReserva> {
  // Criado uma vez só, para o build não abrir conexões novas.
  late final Stream<List<Disciplina>> _disciplinas = disciplinasParaReserva(
    Sessao.usuario,
  );

  Disciplina? _disciplina;
  Turno _turno = Turno.manha;
  DateTime? _diaSelecionado;
  String? _erro;

  // Reservas desta sala, vindas do Firestore e sempre atualizadas: se alguém
  // reservar enquanto o modal está aberto, o dia fica vermelho na hora.
  List<Reserva> _reservasDaSala = const [];
  StreamSubscription<List<Reserva>>? _assinatura;

  // Aulas fixas da grade nesta sala: o dia da semana + turno delas fica
  // ocupado em todas as semanas.
  List<Horario> _aulasFixas = const [];
  StreamSubscription<List<Horario>>? _assinaturaFixas;

  @override
  void initState() {
    super.initState();
    _assinaturaFixas = HorarioService.instancia
        .daSala(widget.sala)
        .listen(
          (aulas) {
            if (!mounted) return;
            setState(() {
              _aulasFixas = aulas;
              final escolhido = _diaSelecionado;
              if (escolhido != null && _estaOcupado(escolhido)) {
                _diaSelecionado = null;
              }
            });
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(
              () => _erro = 'Não foi possível carregar a grade da sala.',
            );
          },
        );
    _assinatura = ReservaService.instancia
        .reservasDaSala(widget.sala)
        .listen(
          (reservas) {
            if (!mounted) return;
            setState(() {
              _reservasDaSala = reservas;
              // O dia escolhido pode ter acabado de ser ocupado.
              final escolhido = _diaSelecionado;
              if (escolhido != null && _estaOcupado(escolhido)) {
                _diaSelecionado = null;
              }
            });
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(() {
              _erro = 'Não foi possível carregar os dias ocupados.';
            });
          },
        );
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _assinaturaFixas?.cancel();
    super.dispose();
  }

  bool _estaOcupado(DateTime dia) {
    final diaSemana = DiaSemanaInfo.de(dia);
    final temAulaFixa = _aulasFixas.any(
      (h) => h.dia == diaSemana && h.turno == _turno,
    );
    return temAulaFixa ||
        _reservasDaSala.any((r) => r.turno == _turno && r.ehDoDia(dia));
  }

  void _adicionar() {
    if (_disciplina == null) {
      setState(() => _erro = 'Selecione a disciplina.');
      return;
    }

    if (_diaSelecionado == null) {
      setState(() => _erro = 'Selecione o dia da reserva.');
      return;
    }

    Navigator.pop(
      context,
      Reserva(
        sala: widget.sala,
        disciplina: _disciplina!.nome,
        disciplinaId: _disciplina!.id,
        turno: _turno,
        data: DateTime(
          _diaSelecionado!.year,
          _diaSelecionado!.month,
          _diaSelecionado!.day,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservando ${widget.sala.rotuloCurto} ${widget.sala.numero}',
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _azulEscuro,
              ),
            ),

            Text(
              widget.sala.descricao,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                color: Color(0xFF7A7A7A),
              ),
            ),

            const SizedBox(height: 14),

            // ----------------------------------------------------------
            // DISCIPLINA
            // ----------------------------------------------------------
            const Text(
              'Selecione a Disciplina',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _azulEscuro,
              ),
            ),

            const SizedBox(height: 6),

            StreamBuilder<List<Disciplina>>(
              stream: _disciplinas,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _AvisoDisciplinas(
                    'Não foi possível carregar as disciplinas.',
                    cor: _vermelho,
                  );
                }

                final disciplinas = snapshot.data;
                if (disciplinas == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (disciplinas.isEmpty) {
                  return _AvisoDisciplinas(switch (Sessao.usuario?.perfil) {
                    PerfilUsuario.professor =>
                      'Você ainda não está em nenhuma disciplina. Peça ao '
                          'administrador para incluir você.',
                    PerfilUsuario.aluno =>
                      'Você ainda não está matriculado em nenhuma disciplina. '
                          'Faça a matrícula pelo menu.',
                    _ => 'Nenhuma disciplina cadastrada.',
                  });
                }

                // A escolha só vale se ainda for uma das opções (a disciplina
                // pode ter sido excluída com o modal aberto).
                final escolhida =
                    disciplinas.any((d) => d.id == _disciplina?.id)
                    ? _disciplina!.id
                    : null;

                return DropdownButtonFormField<String>(
                  initialValue: escolhida,
                  isExpanded: true,
                  hint: const Text(
                    'Disciplina',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                    ),
                  ),
                  items: [
                    for (final disciplina in disciplinas)
                      DropdownMenuItem(
                        value: disciplina.id,
                        child: Text(
                          disciplina.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    setState(() {
                      _disciplina = disciplinas
                          .where((d) => d.id == id)
                          .firstOrNull;
                      _erro = null;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------------
            // TURNO
            // ----------------------------------------------------------
            Row(
              children: [
                for (final turno in Turno.values) ...[
                  Expanded(
                    child: _BotaoTurno(
                      turno: turno,
                      selecionado: _turno == turno,
                      onTap: () {
                        setState(() {
                          _turno = turno;
                          // O dia escolhido pode estar ocupado no novo turno.
                          _diaSelecionado = null;
                          _erro = null;
                        });
                      },
                    ),
                  ),
                  if (turno != Turno.values.last) const SizedBox(width: 6),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------------
            // CALENDÁRIO: vermelho = ocupado, verde = selecionado
            // ----------------------------------------------------------
            CalendarDatePicker2(
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.single,
                firstDate: DateTime.now(),
                lastDate: DateTime(2035),
                selectedDayHighlightColor: _verde,
                disableModePicker: true,
                useAbbrLabelForMonthModePicker: true,
                centerAlignModePicker: true,
                weekdayLabels: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'],
                weekdayLabelTextStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
                controlsTextStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w800,
                  color: _azul,
                ),
                dayTextStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  color: Colors.black87,
                ),
                selectedDayTextStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                dayBorderRadius: BorderRadius.circular(6),
                lastMonthIcon: const Icon(Icons.chevron_left, color: _azul),
                nextMonthIcon: const Icon(Icons.chevron_right, color: _azul),

                // Dia ocupado não pode ser escolhido...
                selectableDayPredicate: (dia) => !_estaOcupado(dia),

                // ...e aparece em vermelho.
                dayBuilder:
                    ({
                      required date,
                      textStyle,
                      decoration,
                      isSelected,
                      isDisabled,
                      isToday,
                    }) {
                      if (!_estaOcupado(date)) return null;

                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _vermelho,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              fontFamily: 'NunitoSans',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
              ),
              value: [_diaSelecionado],
              onValueChanged: (dias) {
                setState(() {
                  _diaSelecionado = dias.isNotEmpty ? dias.first : null;
                  _erro = null;
                });
              },
            ),

            // LEGENDA
            const Row(
              children: [
                _Legenda(cor: _vermelho, texto: 'Ocupado'),
                SizedBox(width: 14),
                _Legenda(cor: _verde, texto: 'Selecionado'),
              ],
            ),

            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _vermelho,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ----------------------------------------------------------
            // BOTÕES
            // ----------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE3E3E3),
                      foregroundColor: const Color(0xFF4A4A4A),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _adicionar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Adicionar',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// BOTÃO DE TURNO
// ================================================================
class _BotaoTurno extends StatelessWidget {
  final Turno turno;
  final bool selecionado;
  final VoidCallback onTap;

  const _BotaoTurno({
    required this.turno,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? _azul : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? _azul : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(
          turno.rotulo,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selecionado ? Colors.white : _azulEscuro,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// LEGENDA DO CALENDÁRIO
// ================================================================
class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;

  const _Legenda({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 12,
            color: Color(0xFF7A7A7A),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// ALERTA DE CONFIRMAÇÃO
// ================================================================

/// Mostra o resumo da reserva. Devolve `true` se o usuário confirmar.
Future<bool> confirmarReserva(BuildContext context, Reserva reserva) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Atenção!',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _azulEscuro,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Você gostaria de confirmar a reserva da sala?',
            style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
          ),
          const SizedBox(height: 12),
          _LinhaResumo(
            titulo: reserva.sala.rotuloCurto,
            valor: reserva.sala.numero,
          ),
          _LinhaResumo(titulo: 'Disciplina', valor: reserva.disciplina),
          _LinhaResumo(
            titulo: 'Turno',
            valor: '${reserva.turno.rotulo} (${reserva.turno.horario})',
          ),
          _LinhaResumo(titulo: 'Dia', valor: formatarDataCurta(reserva.data)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            backgroundColor: _vermelho,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Não',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: _verde,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Sim',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  return confirmou ?? false;
}

// ================================================================
// ALERTA DE SUCESSO
// ================================================================
Future<void> avisarReservaConcluida(
  BuildContext context,
  Reserva reserva,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: _azul, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Concluído!',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _azulEscuro,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${reserva.sala.rotuloCurto} ${reserva.sala.numero} reservada '
            'para ${formatarDataCurta(reserva.data)}!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _azul,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Fechar',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LinhaResumo extends StatelessWidget {
  final String titulo;
  final String valor;

  const _LinhaResumo({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _azulEscuro,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoDisciplinas extends StatelessWidget {
  final String texto;
  final Color cor;

  const _AvisoDisciplinas(this.texto, {this.cor = const Color(0xFF7A7A7A)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        texto,
        style: TextStyle(fontFamily: 'NunitoSans', fontSize: 13, color: cor),
      ),
    );
  }
}
