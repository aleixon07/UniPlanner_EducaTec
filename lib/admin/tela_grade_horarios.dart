import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../model/disciplina.dart';
import '../model/horario.dart';
import '../model/reserva.dart';
import '../model/sala.dart';
import '../model/semestre.dart';
import '../service/disciplina_service.dart';
import '../service/horario_service.dart';
import '../service/sala_service.dart';
import '../sidebar.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Grade de horários de um semestre (a turma): para cada dia da semana e
/// turno, qual disciplina tem aula e em qual sala. Essas aulas se repetem toda
/// semana; as reservas são as exceções.
class TelaGradeHorarios extends StatefulWidget {
  final Curso curso;
  final Semestre semestre;

  const TelaGradeHorarios({
    super.key,
    required this.curso,
    required this.semestre,
  });

  @override
  State<TelaGradeHorarios> createState() => _TelaGradeHorariosState();
}

class _TelaGradeHorariosState extends State<TelaGradeHorarios> {
  late final Stream<List<Horario>> _horarios = HorarioService.instancia
      .doSemestre(widget.semestre.id);
  late final Stream<List<Disciplina>> _disciplinas = DisciplinaService.instancia
      .listar(widget.curso.id);
  late final Stream<List<Sala>> _salas = SalaService.instancia.listar();

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

  Future<void> _abrir({
    required DiaSemana dia,
    required Turno turno,
    required List<Disciplina> disciplinas,
    required List<Sala> salas,
    Horario? atual,
  }) async {
    final salvou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogHorario(
        curso: widget.curso,
        semestre: widget.semestre,
        dia: dia,
        turno: turno,
        disciplinas: disciplinas,
        salas: salas,
        atual: atual,
      ),
    );
    if (salvou == true && mounted) _avisar('Grade atualizada.');
  }

  Future<void> _excluir(Horario horario) async {
    try {
      await HorarioService.instancia.excluir(horario);
      if (mounted) _avisar('Aula tirada da grade.');
    } on ErroHorario catch (e) {
      if (mounted) _avisar(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Disciplina>>(
            stream: _disciplinas,
            builder: (context, snapDisciplinas) {
              return StreamBuilder<List<Sala>>(
                stream: _salas,
                builder: (context, snapSalas) {
                  return StreamBuilder<List<Horario>>(
                    stream: _horarios,
                    builder: (context, snapHorarios) {
                      if (snapDisciplinas.hasError ||
                          snapSalas.hasError ||
                          snapHorarios.hasError) {
                        return const _Mensagem(
                          'Não foi possível carregar a grade. Verifique a '
                          'conexão e as regras do Firestore.',
                          cor: _vermelho,
                        );
                      }

                      final todas = snapDisciplinas.data;
                      final salas = snapSalas.data;
                      final horarios = snapHorarios.data;
                      if (todas == null || salas == null || horarios == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final disciplinas = todas
                          .where((d) => d.semestreId == widget.semestre.id)
                          .toList();
                      final nomes = {for (final d in todas) d.id: d.nome};

                      return _grade(disciplinas, salas, horarios, nomes);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _grade(
    List<Disciplina> disciplinas,
    List<Sala> salas,
    List<Horario> horarios,
    Map<String, String> nomes,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text(
          'Grade de Horários',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _azulEscuro,
          ),
        ),
        Text(
          '${widget.curso.nome} • ${widget.semestre.rotulo}',
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            color: Color(0xFF7A7A7A),
          ),
        ),
        const SizedBox(height: 16),

        if (disciplinas.isEmpty)
          const _Mensagem(
            'Este semestre ainda não tem disciplinas. Cadastre as disciplinas '
            'na tela do curso para montar a grade.',
          )
        else if (salas.isEmpty)
          const _Mensagem(
            'Nenhuma sala cadastrada. Cadastre em Gerenciar Salas > Salas.',
          )
        else
          for (final dia in DiaSemana.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                dia.rotulo,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _azul,
                ),
              ),
            ),
            for (final turno in Turno.values)
              _Celula(
                turno: turno,
                horario: horarios
                    .where((h) => h.dia == dia && h.turno == turno)
                    .firstOrNull,
                nomes: nomes,
                onAbrir: (atual) => _abrir(
                  dia: dia,
                  turno: turno,
                  disciplinas: disciplinas,
                  salas: salas,
                  atual: atual,
                ),
                onExcluir: _excluir,
              ),
          ],
      ],
    );
  }
}

// ================================================================
// UMA CÉLULA DA GRADE (dia + turno)
// ================================================================
class _Celula extends StatelessWidget {
  final Turno turno;
  final Horario? horario;
  final Map<String, String> nomes;
  final void Function(Horario? atual) onAbrir;
  final void Function(Horario) onExcluir;

  const _Celula({
    required this.turno,
    required this.horario,
    required this.nomes,
    required this.onAbrir,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final aula = horario;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: aula == null ? Colors.white : const Color(0xFFF1F1F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: aula == null
              ? const BorderSide(color: Color(0xFFD6D6D6))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onAbrir(aula),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turno.rotulo,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _azulEscuro,
                        ),
                      ),
                      Text(
                        turno.horario,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 11,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: aula == null
                      ? const Text(
                          '+ Adicionar aula',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _azul,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomes[aula.disciplinaId] ?? aula.disciplinaNome,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'NunitoSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _azulEscuro,
                              ),
                            ),
                            Text(
                              '${aula.sala.rotuloCurto} ${aula.sala.numero}',
                              style: const TextStyle(
                                fontFamily: 'NunitoSans',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
                if (aula != null)
                  IconButton(
                    onPressed: () => onExcluir(aula),
                    tooltip: 'Tirar da grade',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: _vermelho,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MODAL: ESCOLHER DISCIPLINA E SALA DE UMA CÉLULA
// ================================================================
class DialogHorario extends StatefulWidget {
  final Curso curso;
  final Semestre semestre;
  final DiaSemana dia;
  final Turno turno;
  final List<Disciplina> disciplinas;
  final List<Sala> salas;
  final Horario? atual;

  const DialogHorario({
    super.key,
    required this.curso,
    required this.semestre,
    required this.dia,
    required this.turno,
    required this.disciplinas,
    required this.salas,
    this.atual,
  });

  @override
  State<DialogHorario> createState() => _DialogHorarioState();
}

class _DialogHorarioState extends State<DialogHorario> {
  late String? _disciplinaId =
      widget.disciplinas.any((d) => d.id == widget.atual?.disciplinaId)
      ? widget.atual!.disciplinaId
      : null;
  late String? _salaId =
      widget.salas.any((s) => Reserva.salaIdDe(s) == widget.atual?.sala.id)
      ? widget.atual!.sala.id
      : null;
  String? _erro;
  bool _salvando = false;

  Future<void> _salvar() async {
    final disciplina = widget.disciplinas
        .where((d) => d.id == _disciplinaId)
        .firstOrNull;
    final sala = widget.salas
        .where((s) => Reserva.salaIdDe(s) == _salaId)
        .firstOrNull;
    if (disciplina == null || sala == null) {
      setState(() => _erro = 'Escolha a disciplina e a sala.');
      return;
    }

    setState(() {
      _erro = null;
      _salvando = true;
    });
    try {
      await HorarioService.instancia.salvar(
        Horario(
          cursoId: widget.curso.id,
          semestreId: widget.semestre.id,
          disciplinaId: disciplina.id,
          disciplinaNome: disciplina.nome,
          dia: widget.dia,
          turno: widget.turno,
          sala: sala,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ErroHorario catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _salvando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro inesperado ao salvar. Tente novamente.';
        _salvando = false;
      });
    }
  }

  InputDecoration _decoracao(String rotulo) => InputDecoration(
    labelText: rotulo,
    labelStyle: const TextStyle(fontFamily: 'NunitoSans'),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_salvando,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.atual == null ? 'Adicionar Aula' : 'Editar Aula',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),
              Text(
                '${widget.dia.rotulo} • ${widget.turno.rotulo} '
                '(${widget.turno.horario})',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 13,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _disciplinaId,
                isExpanded: true,
                dropdownColor: Colors.white,
                decoration: _decoracao('Disciplina'),
                items: [
                  for (final d in widget.disciplinas)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        d.nome,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'NunitoSans'),
                      ),
                    ),
                ],
                onChanged: _salvando
                    ? null
                    : (v) => setState(() {
                        _disciplinaId = v;
                        _erro = null;
                      }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _salaId,
                isExpanded: true,
                dropdownColor: Colors.white,
                decoration: _decoracao('Sala'),
                items: [
                  for (final s in widget.salas)
                    DropdownMenuItem(
                      value: Reserva.salaIdDe(s),
                      child: Text(
                        s.descricao,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'NunitoSans'),
                      ),
                    ),
                ],
                onChanged: _salvando
                    ? null
                    : (v) => setState(() {
                        _salaId = v;
                        _erro = null;
                      }),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _salvando
                          ? null
                          : () => Navigator.pop(context, false),
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
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                              'Salvar',
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
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Mensagem(this.texto, {this.cor = const Color(0xFF7A7A7A)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: cor),
      ),
    );
  }
}
