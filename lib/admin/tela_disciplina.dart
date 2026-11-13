import 'package:flutter/material.dart';

import '../model/disciplina.dart';
import '../model/matricula.dart';
import '../model/usuario.dart';
import '../service/disciplina_service.dart';
import '../service/matricula_service.dart';
import '../service/usuario_service.dart';
import '../sidebar.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);

/// Tela de uma disciplina: mostra os dados dela e os professores vinculados.
///
/// Para vincular, escolha o professor no select (que lista todos os
/// professores cadastrados que ainda não estão na disciplina) e toque em
/// "Adicionar". Cada professor vinculado tem um botão para remover.
///
/// [contexto] é só um texto para situar quem olha (ex.: "Sistemas de
/// Informação • 3º Semestre").
class TelaDisciplina extends StatefulWidget {
  final String disciplinaId;
  final String contexto;

  const TelaDisciplina({
    super.key,
    required this.disciplinaId,
    required this.contexto,
  });

  @override
  State<TelaDisciplina> createState() => _TelaDisciplinaState();
}

class _TelaDisciplinaState extends State<TelaDisciplina> {
  // Criados uma vez só, para o build não abrir conexões novas.
  late final Stream<Disciplina?> _disciplina = DisciplinaService.instancia
      .observar(widget.disciplinaId);
  late final Stream<List<Usuario>> _professores = UsuarioService.instancia
      .listar(PerfilUsuario.professor);

  String? _escolhido;
  bool _salvando = false;

  // Trocar a chave recria o select e o devolve ao estado "Selecione".
  int _versaoSelect = 0;

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

  Future<void> _adicionar(
    Disciplina disciplina,
    List<Usuario> professores,
  ) async {
    final id = _escolhido;
    if (id == null || _salvando) return;

    setState(() => _salvando = true);
    try {
      await DisciplinaService.instancia.adicionarProfessor(disciplina, id);
      if (!mounted) return;
      final nome = professores.where((p) => p.id == id).firstOrNull?.nome;
      _avisar('${nome ?? 'Professor'} adicionado à disciplina.');
      setState(() {
        _escolhido = null;
        _versaoSelect++;
      });
    } on ErroDisciplina catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _avisar('Erro inesperado ao adicionar o professor.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover(Disciplina disciplina, String professorId) async {
    try {
      await DisciplinaService.instancia.removerProfessor(
        disciplina,
        professorId,
      );
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
      body: StreamBuilder<Disciplina?>(
        stream: _disciplina,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Aviso(
              'Não foi possível carregar a disciplina. '
              'Verifique a conexão e as regras do Firestore.',
              cor: _vermelho,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final disciplina = snapshot.data;
          if (disciplina == null) {
            return const _Aviso('Disciplina não encontrada.');
          }

          return _conteudo(disciplina);
        },
      ),
    );
  }

  Widget _conteudo(Disciplina disciplina) {
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
                  child: Icon(Icons.menu_book, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disciplina.nome,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _azulEscuro,
                        ),
                      ),
                      if (widget.contexto.isNotEmpty)
                        Text(
                          widget.contexto,
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 13,
                            color: Color(0xFF7A7A7A),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Professores',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _azulEscuro,
              ),
            ),

            const SizedBox(height: 12),

            StreamBuilder<List<Usuario>>(
              stream: _professores,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Mensagem(
                    'Não foi possível carregar os professores. '
                    'Verifique a conexão e as regras do Firestore.',
                    cor: _vermelho,
                  );
                }

                final todos = snapshot.data;
                if (todos == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _professoresDaDisciplina(disciplina, todos);
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Alunos',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _azulEscuro,
              ),
            ),

            const SizedBox(height: 12),

            _SecaoAlunos(disciplina: disciplina),
          ],
        ),
      ),
    );
  }

  Widget _professoresDaDisciplina(Disciplina disciplina, List<Usuario> todos) {
    // Quem já está na disciplina aparece na lista; o select oferece os outros
    // (só professores ativos).
    final vinculados = disciplina.professorIds;
    final disponiveis = todos
        .where((p) => p.ativo && !vinculados.contains(p.id))
        .toList();

    // O professor escolhido só vale se ainda for uma opção do select. Quando
    // ele acaba de ser adicionado (ou foi desativado por outra pessoa), a lista
    // muda antes de _escolhido ser limpo, e o select quebraria com um valor que
    // não está nas opções.
    final escolhido = disponiveis.any((p) => p.id == _escolhido)
        ? _escolhido
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vinculados.isEmpty)
          const _Mensagem('Nenhum professor nesta disciplina.')
        else
          for (final id in vinculados)
            _ItemProfessor(
              // Professor desativado ou apagado continua aparecendo, para
              // poder ser removido da disciplina.
              nome:
                  todos.where((p) => p.id == id).firstOrNull?.nome ??
                  'Professor não encontrado',
              onRemover: () => _remover(disciplina, id),
            ),

        const SizedBox(height: 12),

        if (todos.isEmpty)
          const _Mensagem(
            'Nenhum professor cadastrado ainda. Cadastre em '
            'Gerenciar Usuários > Professor.',
          )
        else if (disponiveis.isEmpty)
          const _Mensagem('Todos os professores já estão nesta disciplina.')
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_versaoSelect),
                  isExpanded: true,
                  initialValue: escolhido,
                  hint: const Text(
                    'Selecione um professor',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  items: [
                    for (final p in disponiveis)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'NunitoSans'),
                        ),
                      ),
                  ],
                  onChanged: _salvando
                      ? null
                      : (valor) => setState(() => _escolhido = valor),
                  decoration: InputDecoration(
                    isDense: true,
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
              Material(
                color: escolhido == null
                    ? const Color(0xFFEEEEEE)
                    : const Color(0xFFE3E8F8),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: escolhido == null || _salvando
                      ? null
                      : () => _adicionar(disciplina, todos),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: _salvando
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.add,
                            color: escolhido == null
                                ? const Color(0xFFBDBDBD)
                                : _azul,
                            semanticLabel: 'Adicionar professor',
                          ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ================================================================
// PROFESSOR VINCULADO
// ================================================================
class _ItemProfessor extends StatelessWidget {
  final String nome;
  final VoidCallback onRemover;

  const _ItemProfessor({required this.nome, required this.onRemover});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 20, color: _azul),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                nome,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _azulEscuro,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onRemover,
            tooltip: 'Remover professor',
            icon: const Icon(Icons.close, size: 20, color: _vermelho),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: cor),
      ),
    );
  }
}

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

// ================================================================
// ALUNOS MATRICULADOS (o administrador matricula a qualquer momento)
// ================================================================
class _SecaoAlunos extends StatefulWidget {
  final Disciplina disciplina;

  const _SecaoAlunos({required this.disciplina});

  @override
  State<_SecaoAlunos> createState() => _SecaoAlunosState();
}

class _SecaoAlunosState extends State<_SecaoAlunos> {
  late final Stream<List<Matricula>> _matriculas = MatriculaService.instancia
      .daDisciplina(widget.disciplina.id);
  late final Stream<List<Usuario>> _alunos = UsuarioService.instancia.listar(
    PerfilUsuario.aluno,
  );

  String? _escolhido;
  bool _salvando = false;
  int _versaoSelect = 0;

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

  Future<void> _matricular() async {
    final id = _escolhido;
    if (id == null || _salvando) return;
    setState(() => _salvando = true);
    try {
      await MatriculaService.instancia.matricular(id, widget.disciplina);
      if (!mounted) return;
      setState(() {
        _escolhido = null;
        _versaoSelect++;
      });
      _avisar('Aluno matriculado.');
    } on ErroMatricula catch (e) {
      if (mounted) _avisar(e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover(String alunoId) async {
    try {
      await MatriculaService.instancia.cancelar(alunoId, widget.disciplina.id);
    } on ErroMatricula catch (e) {
      if (mounted) _avisar(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Usuario>>(
      stream: _alunos,
      builder: (context, snapAlunos) {
        return StreamBuilder<List<Matricula>>(
          stream: _matriculas,
          builder: (context, snapMatriculas) {
            if (snapAlunos.hasError || snapMatriculas.hasError) {
              return const _Mensagem(
                'Não foi possível carregar os alunos.',
                cor: _vermelho,
              );
            }
            final alunos = snapAlunos.data;
            final matriculas = snapMatriculas.data;
            if (alunos == null || matriculas == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final matriculados = {for (final m in matriculas) m.alunoId};
            final nomes = {for (final a in alunos) a.id: a.nome};
            final disponiveis = alunos
                .where((a) => a.ativo && !matriculados.contains(a.id))
                .toList();
            // Mesmo cuidado do select de professores: o valor só vale se
            // ainda for uma das opções.
            final escolhido = disponiveis.any((a) => a.id == _escolhido)
                ? _escolhido
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (matriculados.isEmpty)
                  const _Mensagem('Nenhum aluno matriculado.')
                else
                  for (final id in matriculados)
                    _ItemProfessor(
                      nome: nomes[id] ?? 'Aluno não encontrado',
                      onRemover: () => _remover(id),
                    ),
                const SizedBox(height: 12),
                if (disponiveis.isEmpty)
                  _Mensagem(
                    alunos.isEmpty
                        ? 'Nenhum aluno cadastrado ainda.'
                        : 'Todos os alunos já estão nesta disciplina.',
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_versaoSelect),
                          isExpanded: true,
                          initialValue: escolhido,
                          hint: const Text(
                            'Selecione um aluno',
                            style: TextStyle(
                              fontFamily: 'NunitoSans',
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                          dropdownColor: Colors.white,
                          items: [
                            for (final a in disponiveis)
                              DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  a.nome,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'NunitoSans',
                                  ),
                                ),
                              ),
                          ],
                          onChanged: _salvando
                              ? null
                              : (v) => setState(() => _escolhido = v),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: escolhido == null || _salvando
                            ? null
                            : _matricular,
                        tooltip: 'Matricular aluno',
                        icon: _salvando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
