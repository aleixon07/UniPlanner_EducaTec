import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'sidebar.dart';

// ============================================================
// MODELO DE AVISO
// ============================================================
class Aviso {
  final String titulo;
  final String descricao;
  final DateTime data;
  final TimeOfDay hora;
  final Color cor;

  const Aviso({
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.hora,
    required this.cor,
  });
}

/// Cores disponíveis para marcar um aviso.
const List<Color> coresAviso = [
  Color(0xFFE85D75),
  Color(0xFFF2994A),
  Color(0xFFF2C94C),
  Color(0xFF27AE60),
  Color(0xFF2D9CDB),
  Color(0xFF3750B5),
  Color(0xFF9B51E0),
  Color(0xFF7A7A7A),
];

const List<String> _diasSemana = [
  'seg.',
  'ter.',
  'qua.',
  'qui.',
  'sex.',
  'sáb.',
  'dom.',
];

const List<String> _mesesAbreviados = [
  'jan.',
  'fev.',
  'mar.',
  'abr.',
  'mai.',
  'jun.',
  'jul.',
  'ago.',
  'set.',
  'out.',
  'nov.',
  'dez.',
];

String formatarData(DateTime data) {
  return '${_diasSemana[data.weekday - 1]}, ${data.day} de '
      '${_mesesAbreviados[data.month - 1]}';
}

String formatarHora(TimeOfDay hora) {
  final h = hora.hour.toString().padLeft(2, '0');
  final m = hora.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ============================================================
// TELA PRINCIPAL
// ============================================================
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  List<DateTime?> _dates = [DateTime.now()];

  /// Avisos de exemplo enquanto não existe persistência.
  final List<Aviso> _avisos = [
    Aviso(
      titulo: 'Reunião',
      descricao: 'Reunião de conselho de classe',
      data: DateTime.now(),
      hora: const TimeOfDay(hour: 17, minute: 30),
      cor: const Color(0xFFE85D75),
    ),
    Aviso(
      titulo: 'Palestra',
      descricao: 'Dar palestra sobre o uso da IA na educação',
      data: DateTime.now(),
      hora: const TimeOfDay(hour: 17, minute: 30),
      cor: const Color(0xFF9B51E0),
    ),
    Aviso(
      titulo: 'Relatório',
      descricao: 'Entregar relatório das bolsas de pesquisa',
      data: DateTime.now().add(const Duration(days: 3)),
      hora: const TimeOfDay(hour: 17, minute: 30),
      cor: const Color(0xFF2D9CDB),
    ),
  ];

  DateTime get _dataSelecionada {
    if (_dates.isNotEmpty && _dates.first != null) {
      return _dates.first!;
    }
    return DateTime.now();
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Aviso> _avisosDoDia(DateTime dia) {
    return _avisos.where((aviso) => _mesmoDia(aviso.data, dia)).toList();
  }

  Future<void> _abrirDialogAviso() async {
    final novoAviso = await showDialog<Aviso>(
      context: context,
      builder: (context) => DialogAviso(dataInicial: _dataSelecionada),
    );

    if (novoAviso != null) {
      setState(() {
        _avisos.add(novoAviso);
        _dates = [novoAviso.data];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avisosDoDia = _avisosDoDia(_dataSelecionada);

    return Scaffold(
      appBar: const AppBarUniPlanner(),
      drawer: const Sidebar(),
      backgroundColor: Colors.grey.shade100,

      body: Column(
        children: [
          // ============================================================
          // CALENDÁRIO
          // ============================================================
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Center(
                child: CalendarDatePicker2(
                  config: CalendarDatePicker2Config(
                    calendarType: CalendarDatePicker2Type.single,
                    firstDayOfWeek: 1,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),

                    weekdayLabels: const [
                      'Dom',
                      'Seg',
                      'Ter',
                      'Qua',
                      'Qui',
                      'Sex',
                      'Sáb',
                    ],

                    weekdayLabelTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),

                    controlsTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3750B5),
                    ),

                    selectedDayHighlightColor: const Color(0xFF3750B5),

                    selectedDayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),

                    dayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      color: Colors.black87,
                    ),

                    todayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3750B5),
                    ),

                    disabledDayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      color: Colors.grey,
                    ),

                    dayBorderRadius: BorderRadius.circular(8),

                    centerAlignModePicker: true,

                    lastMonthIcon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF3750B5),
                    ),

                    nextMonthIcon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF3750B5),
                    ),

                    // ----------------------------------------------------
                    // BOLINHAS DOS DIAS QUE POSSUEM AVISOS
                    // Retornar null faz o pacote desenhar o dia padrão.
                    // ----------------------------------------------------
                    dayBuilder:
                        ({
                          required date,
                          textStyle,
                          decoration,
                          isSelected,
                          isDisabled,
                          isToday,
                        }) {
                          final avisos = _avisosDoDia(date);
                          if (avisos.isEmpty) return null;

                          final cores = avisos
                              .take(3)
                              .map((aviso) => aviso.cor)
                              .toList();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: decoration,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Center(
                                          child: Text(
                                            '${date.day}',
                                            style: textStyle,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              for (final cor in cores)
                                                Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 1,
                                                      ),
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: cor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                  ),

                  value: _dates,

                  onValueChanged: (dates) {
                    setState(() {
                      _dates = dates;
                    });
                  },
                ),
              ),
            ),
          ),

          // ============================================================
          // AVISOS
          // ============================================================
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Avisos',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF203F7D),
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: _abrirDialogAviso,
                        icon: const Icon(Icons.add_circle),
                        color: const Color(0xFF3750B5),
                        tooltip: 'Adicionar aviso',
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Expanded(
                    child: avisosDoDia.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum aviso para este dia.',
                              style: TextStyle(
                                fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: avisosDoDia.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return CardAviso(aviso: avisosDoDia[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // AULAS DO DIA
          // ============================================================
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF203F7D),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Text(
                    'Aulas do Dia',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ÚNICA AULA DE EXEMPLO
                  Expanded(
                    child: Container(
                      width: double.infinity,
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sala',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),

                                SizedBox(height: 2),

                                Text(
                                  '305',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF203F7D),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),

                          // INFORMAÇÕES DA AULA
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Programação',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF203F7D),
                                  ),
                                ),

                                SizedBox(height: 2),

                                Text(
                                  'T30 Informática | 8h - 9h30',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
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

// ============================================================
// CARD DE UM AVISO
// ============================================================
class CardAviso extends StatelessWidget {
  final Aviso aviso;

  const CardAviso({super.key, required this.aviso});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: aviso.cor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          aviso.titulo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF203F7D),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '• ${formatarHora(aviso.hora)}',
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  if (aviso.descricao.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      aviso.descricao,
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DIALOG DE CRIAÇÃO DE AVISO
// ============================================================
class DialogAviso extends StatefulWidget {
  final DateTime dataInicial;

  const DialogAviso({super.key, required this.dataInicial});

  @override
  State<DialogAviso> createState() => _DialogAvisoState();
}

class _DialogAvisoState extends State<DialogAviso> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  late DateTime _data;
  TimeOfDay _hora = const TimeOfDay(hour: 8, minute: 0);
  Color _cor = coresAviso.first;
  bool _tituloVazio = false;

  @override
  void initState() {
    super.initState();
    _data = widget.dataInicial;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (escolhida != null) {
      setState(() {
        _data = escolhida;
      });
    }
  }

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(context: context, initialTime: _hora);

    if (escolhida != null) {
      setState(() {
        _hora = escolhida;
      });
    }
  }

  void _adicionar() {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      setState(() {
        _tituloVazio = true;
      });
      return;
    }

    Navigator.pop(
      context,
      Aviso(
        titulo: titulo,
        descricao: _descricaoController.text.trim(),
        data: _data,
        hora: _hora,
        cor: _cor,
      ),
    );
  }

  InputDecoration _decoracaoCampo(String dica, {String? erro}) {
    return InputDecoration(
      hintText: dica,
      errorText: erro,
      hintStyle: const TextStyle(
        fontFamily: 'NunitoSans',
        color: Color(0xFF9E9E9E),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionando Aviso',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF203F7D),
              ),
            ),

            const SizedBox(height: 16),

            // TÍTULO
            TextField(
              controller: _tituloController,
              style: const TextStyle(fontFamily: 'NunitoSans'),
              decoration: _decoracaoCampo(
                'Título',
                erro: _tituloVazio ? 'Informe um título' : null,
              ),
              onChanged: (_) {
                if (_tituloVazio) {
                  setState(() {
                    _tituloVazio = false;
                  });
                }
              },
            ),

            const SizedBox(height: 10),

            // SELETOR DE COR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final cor in coresAviso)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _cor = cor;
                      });
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cor == cor
                              ? const Color(0xFF203F7D)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // DESCRIÇÃO
            TextField(
              controller: _descricaoController,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'NunitoSans'),
              decoration: _decoracaoCampo('Descrição (opcional)'),
            ),

            const SizedBox(height: 16),

            const Text(
              'Lembrar',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF203F7D),
              ),
            ),

            const SizedBox(height: 8),

            // DATA E HORA
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      formatarData(_data),
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF203F7D),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                OutlinedButton(
                  onPressed: _escolherHora,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF203F7D),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    formatarHora(_hora),
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // BOTÕES
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                      backgroundColor: const Color(0xFF27AE60),
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
