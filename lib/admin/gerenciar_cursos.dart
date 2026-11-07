import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../service/curso_service.dart';
import '../sidebar.dart';
import 'dialog_curso.dart';
import 'tela_curso.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);
const Color _verde = Color(0xFF27AE60);

/// Tela inicial da área administrativa: lista, cadastra, edita e desativa
/// cursos. Tocar em um curso abre a tela dele.
class GerenciarCursos extends StatefulWidget {
  const GerenciarCursos({super.key});

  @override
  State<GerenciarCursos> createState() => _GerenciarCursosState();
}

class _GerenciarCursosState extends State<GerenciarCursos> {
  // Criado uma vez só: se fosse criado no build, cada rebuild abriria uma nova
  // conexão com o Firestore.
  late final Stream<List<Curso>> _cursos = CursoService.instancia.listar();

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

  // O modal já salva no banco; aqui só avisamos. A lista se atualiza sozinha.
  Future<void> _cadastrar() async {
    final nome = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DialogCurso(),
    );

    if (nome == null || !mounted) return;
    _avisar('Curso "$nome" cadastrado.');
  }

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
    final desativando = curso.ativo;

    if (desativando) {
      final confirmou = await confirmarDesativacao(context, curso);
      if (!confirmou || !mounted) return;
    }

    try {
      await CursoService.instancia.definirAtivo(curso.id, !desativando);
      if (!mounted) return;
      _avisar(
        desativando
            ? 'Curso "${curso.nome}" desativado.'
            : 'Curso "${curso.nome}" reativado.',
      );
    } on ErroCurso catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    }
  }

  void _abrir(Curso curso) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaCurso(cursoId: curso.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Curso>>(
            stream: _cursos,
            builder: (context, snapshot) {
              final cursos = snapshot.data;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                children: [
                  const Text(
                    'Gerenciamento de Cursos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _azulEscuro,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ADICIONAR CURSO
                  Center(
                    child: InkWell(
                      onTap: _cadastrar,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Adicionar Curso',
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
                              child: const Icon(
                                Icons.add,
                                color: _azul,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (snapshot.hasError)
                    const _Mensagem(
                      'Não foi possível carregar os cursos. '
                      'Verifique a conexão e as regras do Firestore.',
                      cor: _vermelho,
                    )
                  else if (cursos == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (cursos.isEmpty)
                    const _Mensagem('Nenhum curso cadastrado.')
                  else
                    for (final curso in cursos) ...[
                      _CardCurso(
                        curso: curso,
                        onAbrir: () => _abrir(curso),
                        onEditar: () => _editar(curso),
                        onAlternarAtivo: () => _alternarAtivo(curso),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
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
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: cor),
      ),
    );
  }
}

// ================================================================
// CURSO NA LISTA
// ================================================================
class _CardCurso extends StatelessWidget {
  final Curso curso;
  final VoidCallback onAbrir;
  final VoidCallback onEditar;
  final VoidCallback onAlternarAtivo;

  const _CardCurso({
    required this.curso,
    required this.onAbrir,
    required this.onEditar,
    required this.onAlternarAtivo,
  });

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFBDBDBD)),
    );

    return Material(
      color: curso.ativo ? Colors.white : const Color(0xFFF4F4F4),
      shape: forma,
      child: InkWell(
        onTap: onAbrir,
        customBorder: forma,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.nome,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 15,
                        color: curso.ativo ? Colors.black87 : Colors.black45,
                      ),
                    ),
                    if (!curso.ativo)
                      const Text(
                        'Inativo',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _vermelho,
                        ),
                      ),
                  ],
                ),
              ),

              IconButton(
                onPressed: onEditar,
                tooltip: 'Editar curso',
                icon: const Icon(Icons.edit, color: _azul, size: 20),
              ),

              IconButton(
                onPressed: onAlternarAtivo,
                tooltip: curso.ativo ? 'Desativar curso' : 'Reativar curso',
                icon: curso.ativo
                    ? const Icon(
                        Icons.indeterminate_check_box_outlined,
                        color: _vermelho,
                        size: 22,
                      )
                    : const Icon(Icons.restore, color: _verde, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
