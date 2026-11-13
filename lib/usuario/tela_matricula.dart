import 'package:flutter/material.dart';

import '../model/disciplina.dart';
import '../model/matricula.dart';
import '../model/semestre.dart';
import '../service/disciplina_service.dart';
import '../service/formatador_data.dart';
import '../service/matricula_service.dart';
import '../service/semestre_service.dart';
import '../service/sessao.dart';
import '../sidebar.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Matrícula do aluno: no período aberto pelo administrador, ele escolhe as
/// disciplinas dos semestres liberados do curso dele (inclusive de semestres
/// diferentes do seu). Fora do período, só vê em que está matriculado.
class TelaMatricula extends StatefulWidget {
  const TelaMatricula({super.key});

  @override
  State<TelaMatricula> createState() => _TelaMatriculaState();
}

class _TelaMatriculaState extends State<TelaMatricula> {
  final String _alunoId = Sessao.usuario?.id ?? '';
  final String? _cursoId = Sessao.usuario?.cursoId;

  late final Stream<PeriodoMatricula> _periodo = MatriculaService.instancia
      .periodo();
  late final Stream<List<Matricula>> _matriculas = MatriculaService.instancia
      .doAluno(_alunoId);
  late final Stream<List<Semestre>> _semestres = _cursoId == null
      ? Stream.value(const [])
      : SemestreService.instancia.listar(_cursoId);
  late final Stream<List<Disciplina>> _disciplinas = _cursoId == null
      ? Stream.value(const [])
      : DisciplinaService.instancia.listar(_cursoId);

  // Disciplinas com matrícula/cancelamento em andamento (trava o botão).
  final Set<String> _ocupadas = {};

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

  Future<void> _alternar(Disciplina disciplina, bool matriculado) async {
    setState(() => _ocupadas.add(disciplina.id));
    try {
      if (matriculado) {
        await MatriculaService.instancia.cancelar(_alunoId, disciplina.id);
        if (mounted) _avisar('Matrícula em "${disciplina.nome}" cancelada.');
      } else {
        await MatriculaService.instancia.matricular(_alunoId, disciplina);
        if (mounted) _avisar('Matriculado em "${disciplina.nome}".');
      }
    } on ErroMatricula catch (e) {
      if (mounted) _avisar(e.mensagem);
    } finally {
      if (mounted) setState(() => _ocupadas.remove(disciplina.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _cursoId == null
              ? const _Mensagem(
                  'Você ainda não está em um curso. Peça ao administrador para '
                  'incluir você no seu curso.',
                )
              : _carregar(),
        ),
      ),
    );
  }

  Widget _carregar() {
    return StreamBuilder<PeriodoMatricula>(
      stream: _periodo,
      builder: (context, snapPeriodo) {
        return StreamBuilder<List<Semestre>>(
          stream: _semestres,
          builder: (context, snapSemestres) {
            return StreamBuilder<List<Disciplina>>(
              stream: _disciplinas,
              builder: (context, snapDisciplinas) {
                return StreamBuilder<List<Matricula>>(
                  stream: _matriculas,
                  builder: (context, snapMatriculas) {
                    if (snapPeriodo.hasError ||
                        snapSemestres.hasError ||
                        snapDisciplinas.hasError ||
                        snapMatriculas.hasError) {
                      return const _Mensagem(
                        'Não foi possível carregar a matrícula.',
                        cor: _vermelho,
                      );
                    }
                    final periodo = snapPeriodo.data;
                    final semestres = snapSemestres.data;
                    final disciplinas = snapDisciplinas.data;
                    final matriculas = snapMatriculas.data;
                    if (periodo == null ||
                        semestres == null ||
                        disciplinas == null ||
                        matriculas == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _conteudo(periodo, semestres, disciplinas, {
                      for (final m in matriculas) m.disciplinaId,
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _conteudo(
    PeriodoMatricula periodo,
    List<Semestre> semestres,
    List<Disciplina> disciplinas,
    Set<String> matriculadas,
  ) {
    final aberto = periodo.abertoEm(DateTime.now());
    final numeroDo = {for (final s in semestres) s.id: s.numero};
    final rotuloDo = {for (final s in semestres) s.id: s.rotulo};

    // Pode mexer na disciplina se o período está aberto e o semestre dela foi
    // liberado.
    bool editavel(Disciplina d) =>
        aberto && periodo.liberado(numeroDo[d.semestreId] ?? 0);

    final minhas = disciplinas
        .where((d) => matriculadas.contains(d.id))
        .toList();
    final liberados = aberto
        ? semestres.where((s) => periodo.liberado(s.numero)).toList()
        : const <Semestre>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const Text(
          'Matrícula',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _azulEscuro,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: aberto ? const Color(0xFFE6F6EC) : const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            aberto
                ? 'Matrículas abertas até ${formatarData(periodo.fim!)}.'
                : 'As matrículas estão fechadas. Aguarde o período definido '
                      'pela coordenação.',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: aberto ? _verde : _azulEscuro,
            ),
          ),
        ),

        const SizedBox(height: 24),
        const _Titulo('Minhas disciplinas'),
        const SizedBox(height: 8),
        if (minhas.isEmpty)
          const _Mensagem('Você ainda não está matriculado em disciplinas.')
        else
          for (final d in minhas)
            _ItemDisciplina(
              disciplina: d,
              semestre: rotuloDo[d.semestreId] ?? '',
              matriculado: true,
              editavel: editavel(d),
              ocupada: _ocupadas.contains(d.id),
              onAlternar: () => _alternar(d, true),
            ),

        for (final semestre in liberados) ...[
          const SizedBox(height: 24),
          _Titulo('Disponíveis • ${semestre.rotulo}'),
          const SizedBox(height: 8),
          if (!disciplinas.any((d) => d.semestreId == semestre.id))
            const _Mensagem('Nenhuma disciplina neste semestre.')
          else
            for (final d in disciplinas.where(
              (d) => d.semestreId == semestre.id,
            ))
              _ItemDisciplina(
                disciplina: d,
                semestre: semestre.rotulo,
                matriculado: matriculadas.contains(d.id),
                editavel: true,
                ocupada: _ocupadas.contains(d.id),
                onAlternar: () => _alternar(d, matriculadas.contains(d.id)),
              ),
        ],
      ],
    );
  }
}

class _ItemDisciplina extends StatelessWidget {
  final Disciplina disciplina;
  final String semestre;
  final bool matriculado;
  final bool editavel;
  final bool ocupada;
  final VoidCallback onAlternar;

  const _ItemDisciplina({
    required this.disciplina,
    required this.semestre,
    required this.matriculado,
    required this.editavel,
    required this.ocupada,
    required this.onAlternar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disciplina.nome,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _azulEscuro,
                  ),
                ),
                if (semestre.isNotEmpty)
                  Text(
                    semestre,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 12,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
              ],
            ),
          ),
          if (ocupada)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (editavel)
            TextButton(
              onPressed: onAlternar,
              style: TextButton.styleFrom(
                foregroundColor: matriculado ? _vermelho : _azul,
              ),
              child: Text(
                matriculado ? 'Cancelar' : 'Matricular',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (matriculado)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check_circle, color: _verde, size: 20),
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
