import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../model/disciplina.dart';
import '../model/semestre.dart';
import '../service/curso_service.dart';
import '../service/disciplina_service.dart';
import '../service/semestre_service.dart';
import '../sidebar.dart';
import 'dialog_curso.dart';
import 'dialog_disciplina.dart';
import 'dialog_semestre.dart';
import 'tela_disciplina.dart';
import 'tela_grade_horarios.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);
const Color _verde = Color(0xFF27AE60);

/// Decide quais semestres ficam abertos depois que o usuário toca no semestre
/// de id [semestreId]. Recebe o conjunto atual e devolve o novo.
Set<String> alternarSemestre(Set<String> abertos, String semestreId) {
  // Decisão em aberto: hoje vários semestres podem ficar abertos ao mesmo
  // tempo (tocar abre ou fecha só aquele). Se preferirem que abrir um semestre
  // feche os outros, é só mudar aqui.
  final novos = {...abertos};
  if (!novos.remove(semestreId)) novos.add(semestreId);
  return novos;
}

/// Tela de um curso: mostra os dados do curso (com editar e desativar/reativar)
/// e, logo abaixo, os semestres dele em formato de acordeão.
///
/// Semestre se adiciona direto na tela, sem modal: o botão "Adicionar
/// semestre" fica no fim da lista. O lápis muda o número do semestre e a
/// lixeira exclui.
/// Ao abrir um semestre aparecem as disciplinas dele, com um campo para
/// adicionar mais direto ali, e editar/excluir em cada uma.
class TelaCurso extends StatefulWidget {
  final String cursoId;

  const TelaCurso({super.key, required this.cursoId});

  @override
  State<TelaCurso> createState() => _TelaCursoState();
}

class _TelaCursoState extends State<TelaCurso> {
  // Ouvem o Firestore: editar, desativar ou mexer nos semestres atualiza a
  // tela sozinho. Criados uma vez só, para o build não abrir conexões novas.
  late final Stream<Curso?> _curso = CursoService.instancia.observar(
    widget.cursoId,
  );
  late final Stream<List<Semestre>> _semestres = SemestreService.instancia
      .listar(widget.cursoId);
  late final Stream<List<Disciplina>> _disciplinas = DisciplinaService.instancia
      .listar(widget.cursoId);

  // Ids dos semestres abertos.
  Set<String> _abertos = {};

  // Trava o botão de adicionar enquanto grava: dois toques seguidos
  // calculariam o mesmo "próximo número" e criariam um semestre repetido.
  bool _adicionando = false;

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

  // O modal já salva no banco, e a tela se atualiza sozinha pelo stream.
  Future<void> _editar(Curso curso) async {
    final nome = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogCurso(curso: curso),
    );

    if (nome == null || !mounted) return;
    _avisar('Curso atualizado.');
  }

  Future<void> _alternarAtivo(Curso curso) async {
    if (curso.ativo) {
      final confirmou = await confirmarDesativacao(context, curso);
      if (!confirmou || !mounted) return;
    }

    try {
      await CursoService.instancia.definirAtivo(curso.id, !curso.ativo);
    } on ErroCurso catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    }
  }

  // Adicionar é direto, sem modal: cria o próximo semestre e ele aparece
  // embaixo, pelo stream.
  Future<void> _adicionarSemestre(Curso curso) async {
    setState(() => _adicionando = true);

    try {
      final semestre = await SemestreService.instancia.adicionar(curso.id);
      if (!mounted) return;
      _avisar('${semestre.rotulo} adicionado.');
    } on ErroSemestre catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _avisar('Erro inesperado ao adicionar o semestre.');
    } finally {
      if (mounted) setState(() => _adicionando = false);
    }
  }

  // Semestres → disciplinas: dois streams, um dentro do outro.
  Widget _secaoSemestres(Curso curso) {
    return StreamBuilder<List<Semestre>>(
      stream: _semestres,
      builder: (context, snapSemestres) {
        if (snapSemestres.hasError) {
          return const _Mensagem(
            'Não foi possível carregar os semestres. '
            'Verifique a conexão e as regras do Firestore.',
            cor: _vermelho,
          );
        }

        final semestres = snapSemestres.data;
        if (semestres == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<List<Disciplina>>(
          stream: _disciplinas,
          builder: (context, snapDisciplinas) {
            final disciplinas = snapDisciplinas.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (semestres.isEmpty)
                  const _Mensagem('Este curso ainda não tem semestres.'),
                for (final semestre in semestres) ...[
                  _Semestre(
                    semestre: semestre,
                    aberto: _abertos.contains(semestre.id),
                    disciplinas: disciplinas
                        ?.where((d) => d.semestreId == semestre.id)
                        .toList(),
                    erroDisciplinas: snapDisciplinas.hasError,
                    onTap: () => setState(
                      () => _abertos = alternarSemestre(_abertos, semestre.id),
                    ),
                    onEditar: () => _editarSemestre(semestre),
                    onExcluir: () => _excluirSemestre(curso, semestre),
                    onAdicionarDisciplina: (nome) =>
                        _adicionarDisciplina(semestre, nome),
                    onAbrirDisciplina: (d) =>
                        _abrirDisciplina(curso, semestre, d),
                    onAbrirGrade: () => _abrirGrade(curso, semestre),
                    onEditarDisciplina: _editarDisciplina,
                    onExcluirDisciplina: _excluirDisciplina,
                  ),
                  const SizedBox(height: 12),
                ],

                // ADICIONAR SEMESTRE: direto, o semestre novo aparece acima
                // deste botão, que fica sempre no fim da lista.
                _BotaoAdicionarSemestre(
                  carregando: _adicionando,
                  onTap: () => _adicionarSemestre(curso),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // O modal já salva no banco, e a tela se atualiza sozinha pelo stream.
  Future<void> _editarSemestre(Semestre semestre) async {
    final numero = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogSemestre(semestre: semestre),
    );

    if (numero == null || !mounted) return;
    _avisar('Semestre atualizado.');
  }

  Future<void> _excluirSemestre(Curso curso, Semestre semestre) async {
    final confirmou = await confirmarExclusaoSemestre(context, semestre, curso);
    if (!confirmou || !mounted) return;

    try {
      await SemestreService.instancia.excluir(semestre);
      if (!mounted) return;
      setState(() => _abertos = {..._abertos}..remove(semestre.id));
      _avisar('${semestre.rotulo} excluído.');
    } on ErroSemestre catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    }
  }

  // Devolve a mensagem de erro (para o campo mostrar) ou null se deu certo.
  Future<String?> _adicionarDisciplina(Semestre semestre, String nome) async {
    try {
      await DisciplinaService.instancia.adicionar(semestre, nome);
      return null;
    } on ErroDisciplina catch (e) {
      return e.mensagem;
    } catch (_) {
      return 'Erro inesperado ao adicionar a disciplina.';
    }
  }

  void _abrirGrade(Curso curso, Semestre semestre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaGradeHorarios(curso: curso, semestre: semestre),
      ),
    );
  }

  void _abrirDisciplina(Curso curso, Semestre semestre, Disciplina disciplina) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDisciplina(
          disciplinaId: disciplina.id,
          contexto: '${curso.nome} • ${semestre.rotulo}',
        ),
      ),
    );
  }

  Future<void> _editarDisciplina(Disciplina disciplina) async {
    final nome = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogDisciplina(disciplina: disciplina),
    );

    if (nome == null || !mounted) return;
    _avisar('Disciplina atualizada.');
  }

  Future<void> _excluirDisciplina(Disciplina disciplina) async {
    final confirmou = await confirmarExclusaoDisciplina(context, disciplina);
    if (!confirmou || !mounted) return;

    try {
      await DisciplinaService.instancia.excluir(disciplina);
      if (!mounted) return;
      _avisar('Disciplina excluída.');
    } on ErroDisciplina catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      backgroundColor: Colors.white,
      body: StreamBuilder<Curso?>(
        stream: _curso,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Aviso(
              'Não foi possível carregar o curso. '
              'Verifique a conexão e as regras do Firestore.',
              cor: _vermelho,
            );
          }

          // Antes do primeiro dado, data também é nulo; só depois dele é que
          // nulo significa "o curso não existe".
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final curso = snapshot.data;
          if (curso == null) return const _Aviso('Curso não encontrado.');

          return _conteudo(curso);
        },
      ),
    );
  }

  Widget _conteudo(Curso curso) {
    return Align(
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

            _secaoSemestres(curso),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SEMESTRE (ITEM DO ACORDEÃO)
// ================================================================
class _Semestre extends StatelessWidget {
  final Semestre semestre;
  final bool aberto;
  // null enquanto as disciplinas carregam.
  final List<Disciplina>? disciplinas;
  final bool erroDisciplinas;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final Future<String?> Function(String nome) onAdicionarDisciplina;
  final void Function(Disciplina) onAbrirDisciplina;
  final VoidCallback onAbrirGrade;
  final void Function(Disciplina) onEditarDisciplina;
  final void Function(Disciplina) onExcluirDisciplina;

  const _Semestre({
    required this.semestre,
    required this.aberto,
    required this.disciplinas,
    required this.erroDisciplinas,
    required this.onTap,
    required this.onEditar,
    required this.onExcluir,
    required this.onAdicionarDisciplina,
    required this.onAbrirDisciplina,
    required this.onAbrirGrade,
    required this.onEditarDisciplina,
    required this.onExcluirDisciplina,
  });

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          semestre.rotulo,
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: aberto ? Colors.white : _azulEscuro,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onEditar,
                        tooltip: 'Editar semestre',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        icon: Icon(
                          Icons.edit,
                          size: 19,
                          color: aberto ? Colors.white : _azul,
                        ),
                      ),
                      IconButton(
                        onPressed: onExcluir,
                        tooltip: 'Excluir semestre',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 21,
                          color: aberto ? Colors.white : _vermelho,
                        ),
                      ),
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
                ? Padding(padding: const EdgeInsets.all(12), child: _corpo())
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _corpo() {
    final lista = disciplinas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GRADE DE HORÁRIOS DESTE SEMESTRE
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAbrirGrade,
            icon: const Icon(Icons.calendar_view_week, size: 18),
            label: const Text(
              'Grade de horários',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: _azul),
          ),
        ),
        const SizedBox(height: 4),

        if (erroDisciplinas)
          const _Mensagem(
            'Não foi possível carregar as disciplinas.',
            cor: _vermelho,
          )
        else if (lista == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (lista.isEmpty)
          const _Mensagem('Nenhuma disciplina cadastrada neste semestre.')
        else
          for (final disciplina in lista)
            _ItemDisciplina(
              disciplina: disciplina,
              onAbrir: () => onAbrirDisciplina(disciplina),
              onEditar: () => onEditarDisciplina(disciplina),
              onExcluir: () => onExcluirDisciplina(disciplina),
            ),

        const SizedBox(height: 4),

        _NovaDisciplina(onAdicionar: onAdicionarDisciplina),
      ],
    );
  }
}

// ================================================================
// DISCIPLINA DENTRO DO SEMESTRE
// ================================================================
class _ItemDisciplina extends StatelessWidget {
  final Disciplina disciplina;
  final VoidCallback onAbrir;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _ItemDisciplina({
    required this.disciplina,
    required this.onAbrir,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Tocar no nome abre a tela da disciplina.
            Expanded(
              child: InkWell(
                onTap: onAbrir,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          disciplina.nome,
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _azulEscuro,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: _azulEscuro,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onEditar,
              tooltip: 'Editar disciplina',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(Icons.edit, size: 18, color: _azul),
            ),
            IconButton(
              onPressed: onExcluir,
              tooltip: 'Excluir disciplina',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: _vermelho,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CAMPO "ADICIONAR DISCIPLINA" (fim do corpo do semestre)
// ================================================================
class _NovaDisciplina extends StatefulWidget {
  // Devolve a mensagem de erro, ou null se salvou.
  final Future<String?> Function(String nome) onAdicionar;

  const _NovaDisciplina({required this.onAdicionar});

  @override
  State<_NovaDisciplina> createState() => _NovaDisciplinaState();
}

class _NovaDisciplinaState extends State<_NovaDisciplina> {
  final TextEditingController _controller = TextEditingController();
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _adicionar() async {
    if (_salvando) return;
    setState(() {
      _erro = null;
      _salvando = true;
    });

    final erro = await widget.onAdicionar(_controller.text);
    if (!mounted) return;

    setState(() {
      _salvando = false;
      _erro = erro;
      if (erro == null) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_salvando,
            maxLength: FirebaseDisciplinaService.tamanhoMaximoNome,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _adicionar(),
            onChanged: (_) {
              if (_erro != null) setState(() => _erro = null);
            },
            style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nova disciplina',
              errorText: _erro,
              errorMaxLines: 2,
              counterText: '',
              isDense: true,
              hintStyle: const TextStyle(
                fontFamily: 'NunitoSans',
                color: Color(0xFF9E9E9E),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
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
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Material(
            color: const Color(0xFFE3E8F8),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _salvando ? null : _adicionar,
              child: SizedBox(
                width: 42,
                height: 42,
                child: _salvando
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.add,
                        color: _azul,
                        semanticLabel: 'Adicionar disciplina',
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// BOTÃO "ADICIONAR SEMESTRE" (fim da lista)
// ================================================================
class _BotaoAdicionarSemestre extends StatelessWidget {
  final bool carregando;
  final VoidCallback onTap;

  const _BotaoAdicionarSemestre({
    required this.carregando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: carregando ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adicionar semestre',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _azul,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3E8F8),
                  shape: BoxShape.circle,
                ),
                child: carregando
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, color: _azul, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MENSAGEM NO MEIO DA TELA (lista vazia, erro ao carregar)
// ================================================================
class _Mensagem extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Mensagem(this.texto, {this.cor = const Color(0xFF7A7A7A)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: cor),
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

// ================================================================
// MENSAGEM CENTRALIZADA (erro, curso inexistente)
// ================================================================
class _Aviso extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Aviso(this.texto, {this.cor = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'NunitoSans', fontSize: 16, color: cor),
        ),
      ),
    );
  }
}
