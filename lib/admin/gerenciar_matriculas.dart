import 'package:flutter/material.dart';

import '../model/matricula.dart';
import '../service/formatador_data.dart';
import '../service/matricula_service.dart';
import '../service/semestre_service.dart';
import '../sidebar.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Administrador define o período de matrícula: de quando a quando os alunos
/// podem se inscrever sozinhos, e em quais semestres (por número).
class GerenciarMatriculas extends StatefulWidget {
  const GerenciarMatriculas({super.key});

  @override
  State<GerenciarMatriculas> createState() => _GerenciarMatriculasState();
}

class _GerenciarMatriculasState extends State<GerenciarMatriculas> {
  late final Stream<PeriodoMatricula> _periodo = MatriculaService.instancia
      .periodo();

  // Rascunho do formulário; null até o primeiro valor chegar do banco.
  DateTime? _inicio;
  DateTime? _fim;
  Set<int> _semestres = {};
  bool _carregado = false;
  bool _salvando = false;

  void _avisar(String mensagem) {
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

  Future<void> _escolherDatas() async {
    final agora = DateTime.now();
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(agora.year - 1),
      lastDate: DateTime(agora.year + 2),
      initialDateRange: _inicio != null && _fim != null
          ? DateTimeRange(start: _inicio!, end: _fim!)
          : null,
      helpText: 'Período de matrícula',
      saveText: 'OK',
    );
    if (intervalo == null) return;
    setState(() {
      _inicio = intervalo.start;
      _fim = intervalo.end;
    });
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await MatriculaService.instancia.salvarPeriodo(
        PeriodoMatricula(
          inicio: _inicio,
          fim: _fim,
          semestres: _semestres.toList(),
        ),
      );
      if (mounted) _avisar('Período de matrícula salvo.');
    } on ErroMatricula catch (e) {
      if (mounted) _avisar(e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _encerrar() async {
    setState(() {
      _inicio = null;
      _fim = null;
      _semestres = {};
    });
    await _salvar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,
      body: StreamBuilder<PeriodoMatricula>(
        stream: _periodo,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar o período.',
                style: TextStyle(fontFamily: 'NunitoSans', color: _vermelho),
              ),
            );
          }
          final salvo = snapshot.data;
          if (salvo == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Preenche o formulário uma vez, com o que está salvo.
          if (!_carregado) {
            _carregado = true;
            _inicio = salvo.inicio;
            _fim = salvo.fim;
            _semestres = {...salvo.semestres};
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                children: [
                  const Text(
                    'Período de Matrícula',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _azulEscuro,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SITUAÇÃO ATUAL (o que está salvo, não o rascunho)
                  _Situacao(periodo: salvo),

                  const SizedBox(height: 24),
                  const _Titulo('Datas'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _salvando ? null : _escolherDatas,
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _inicio == null || _fim == null
                          ? 'Escolher início e fim'
                          : '${formatarData(_inicio!)} até ${formatarData(_fim!)}',
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _azul,
                      side: const BorderSide(color: _azul),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _Titulo('Semestres liberados'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var n = 1; n <= SemestreService.maximoPorCurso; n++)
                        FilterChip(
                          label: Text(
                            '$nº',
                            style: const TextStyle(fontFamily: 'NunitoSans'),
                          ),
                          selected: _semestres.contains(n),
                          selectedColor: const Color(0xFFE3E8F8),
                          checkmarkColor: _azul,
                          onSelected: _salvando
                              ? null
                              : (marcado) => setState(
                                  () => marcado
                                      ? _semestres.add(n)
                                      : _semestres.remove(n),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _salvando
                            ? null
                            : () => setState(
                                () => _semestres = {
                                  for (var n = 1; n <= 12; n += 2) n,
                                },
                              ),
                        child: const Text('Ímpares'),
                      ),
                      TextButton(
                        onPressed: _salvando
                            ? null
                            : () => setState(
                                () => _semestres = {
                                  for (var n = 2; n <= 12; n += 2) n,
                                },
                              ),
                        child: const Text('Pares'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Salvar período',
                            style: TextStyle(
                              fontFamily: 'NunitoSans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _salvando ? null : _encerrar,
                    style: TextButton.styleFrom(foregroundColor: _vermelho),
                    child: const Text(
                      'Encerrar matrículas agora',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Situacao extends StatelessWidget {
  final PeriodoMatricula periodo;

  const _Situacao({required this.periodo});

  @override
  Widget build(BuildContext context) {
    final aberto = periodo.abertoEm(DateTime.now());
    final i = periodo.inicio;
    final f = periodo.fim;

    final String detalhe;
    if (i == null || f == null || periodo.semestres.isEmpty) {
      detalhe = 'Nenhum período definido.';
    } else {
      detalhe =
          '${formatarData(i)} até ${formatarData(f)} • semestres '
          '${periodo.semestres.map((n) => '$nº').join(', ')}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: aberto ? const Color(0xFFE6F6EC) : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            aberto ? 'Matrículas abertas' : 'Matrículas fechadas',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: aberto ? _verde : _azulEscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detalhe,
            style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontFamily: 'NunitoSans',
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _azulEscuro,
      ),
    );
  }
}
