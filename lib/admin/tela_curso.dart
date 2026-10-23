import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../model/disciplina.dart';
import '../service/curso_service.dart';
import '../service/formatador_data.dart';
import '../sidebar.dart';
import 'dialog_curso.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);
const Color _verde = Color(0xFF27AE60);

/// Decide quais semestres ficam abertos depois que o usuário toca em
/// [semestre]. Recebe o conjunto atual e devolve o novo.
Set<int> alternarSemestre(Set<int> abertos, int semestre) {
  // Decisão em aberto: hoje vários semestres podem ficar abertos ao mesmo
  // tempo (tocar abre ou fecha só aquele). Se preferirem que abrir um semestre
  // feche os outros, é só mudar aqui.
  final novos = {...abertos};
  if (!novos.remove(semestre)) novos.add(semestre);
  return novos;
}

/// Tela de um curso: mostra os dados do curso (com editar e desativar/reativar)
/// e, logo abaixo, os semestres em formato de acordeão, cada um com as
/// disciplinas ofertadas nele.
///
/// A parte das disciplinas é só visual por enquanto: os botões de editar e
/// excluir disciplina ainda não fazem nada, porque o cadastro vem depois.
class TelaCurso extends StatefulWidget {
  final String cursoId;

  const TelaCurso({super.key, required this.cursoId});

  @override
  State<TelaCurso> createState() => _TelaCursoState();
}

class _TelaCursoState extends State<TelaCurso> {
  Set<int> _abertos = {};

  @override
  void initState() {
    super.initState();

    // Começa com o primeiro semestre que tem disciplina aberto, para a tela
    // não abrir como uma fila de barras fechadas.
    for (var s = 1; s <= CursoService.semestresPorCurso; s++) {
      if (CursoService.disciplinasDoSemestre(widget.cursoId, s).isNotEmpty) {
        _abertos = {s};
        break;
      }
    }
  }

  Future<void> _editar(Curso curso) async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => DialogCurso(curso: curso),
    );

    if (nome == null || !mounted) return;

    setState(() => CursoService.editar(curso.id, nome));
  }

  Future<void> _alternarAtivo(Curso curso) async {
    if (curso.ativo) {
      final confirmou = await confirmarDesativacao(context, curso);
      if (!confirmou || !mounted) return;
    }

    setState(() => CursoService.definirAtivo(curso.id, !curso.ativo));
  }

  @override
  Widget build(BuildContext context) {
    final curso = CursoService.buscar(widget.cursoId);

    if (curso == null) {
      return const Scaffold(
        appBar: AppBarUniPlanner(admin: true),
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Curso não encontrado.',
            style: TextStyle(fontFamily: 'NunitoSans', fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            children: [
              // CABEÇALHO
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: _azul,
                    child: Icon(Icons.school, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      curso.nome,
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _azulEscuro,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // DADOS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _Linha(titulo: 'Nome', valor: curso.nome),
                    const SizedBox(height: 10),
                    _Linha(
                      titulo: 'Situação',
                      valor: curso.ativo ? 'Ativo' : 'Inativo',
                      corValor: curso.ativo ? _verde : _vermelho,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // AÇÕES DO CURSO
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editar(curso),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'Editar',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _azul,
                        side: const BorderSide(color: _azul),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _alternarAtivo(curso),
                      icon: Icon(
                        curso.ativo
                            ? Icons.indeterminate_check_box_outlined
                            : Icons.restore,
                        size: 18,
                      ),
                      label: Text(
                        curso.ativo ? 'Desativar' : 'Reativar',
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: curso.ativo ? _vermelho : _verde,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // SEMESTRES (ACORDEÃO)
              const Text(
                'Semestres',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),

              const SizedBox(height: 12),

              for (var s = 1; s <= CursoService.semestresPorCurso; s++) ...[
                _Semestre(
                  numero: s,
                  disciplinas: CursoService.disciplinasDoSemestre(curso.id, s),
                  aberto: _abertos.contains(s),
                  onTap: () {
                    setState(() => _abertos = alternarSemestre(_abertos, s));
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SEMESTRE (ITEM DO ACORDEÃO)
// ================================================================
class _Semestre extends StatelessWidget {
  final int numero;
  final List<Disciplina> disciplinas;
  final bool aberto;
  final VoidCallback onTap;

  const _Semestre({
    required this.numero,
    required this.disciplinas,
    required this.aberto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final quantidade = disciplinas.length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: aberto ? _azul : const Color(0xFFBDBDBD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABEÇALHO: azul quando aberto, igual aos itens do menu lateral
          Material(
            color: aberto ? _azul : Colors.white,
            child: Semantics(
              button: true,
              expanded: aberto,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$numeroº Semestre',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: aberto ? Colors.white : _azulEscuro,
                          ),
                        ),
                      ),
                      Text(
                        quantidade == 1
                            ? '1 disciplina'
                            : '$quantidade disciplinas',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          color: aberto ? Colors.white70 : Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        aberto
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: aberto ? Colors.white : _azulEscuro,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CORPO: anima a abertura e o fechamento
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: aberto
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: disciplinas.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Nenhuma disciplina cadastrada neste semestre.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < disciplinas.length; i++) ...[
                                if (i > 0) const SizedBox(height: 8),
                                _CardDisciplina(disciplina: disciplinas[i]),
                              ],
                            ],
                          ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DISCIPLINA DENTRO DO SEMESTRE
// ================================================================
class _CardDisciplina extends StatelessWidget {
  final Disciplina disciplina;

  const _CardDisciplina({required this.disciplina});

  String _horario(HorarioAula h) {
    return '${h.dia.rotulo} | ${formatarHoraCurta(h.inicio)} - '
        '${formatarHoraCurta(h.fim)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SALA
            Container(
              width: 75,
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
                    disciplina.sala.rotuloCurto,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disciplina.sala.numero,
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

            const SizedBox(width: 12),

            // INFORMAÇÕES
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      disciplina.nome,
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _azulEscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prof: ${disciplina.professor}',
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final horario in disciplina.horarios)
                      Text(
                        _horario(horario),
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // AÇÕES (ainda sem função: o cadastro de disciplinas vem depois)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    // TODO: abrir a edição quando o cadastro de disciplinas existir.
                    onPressed: () {},
                    tooltip: 'Editar disciplina',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    icon: const Icon(Icons.edit, color: _azul, size: 19),
                  ),
                  IconButton(
                    // TODO: pedir confirmação e excluir quando o cadastro existir.
                    onPressed: () {},
                    tooltip: 'Excluir disciplina',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: _vermelho,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LINHA "TÍTULO: VALOR" DO CARD DE DADOS
// ================================================================
class _Linha extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color? corValor;

  const _Linha({required this.titulo, required this.valor, this.corValor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            titulo,
            style: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _azulEscuro,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              fontWeight: corValor != null ? FontWeight.w700 : null,
              color: corValor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
