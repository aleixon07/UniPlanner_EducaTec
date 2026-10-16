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

  Future<void> _cadastrar() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => const DialogCurso(),
    );

    if (nome == null || !mounted) return;

    setState(() => CursoService.adicionar(nome));
    _avisar('Curso "$nome" cadastrado.');
  }

  Future<void> _editar(Curso curso) async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => DialogCurso(curso: curso),
    );

    if (nome == null || !mounted) return;

    setState(() => CursoService.editar(curso.id, nome));
    _avisar('Curso atualizado.');
  }

  Future<void> _alternarAtivo(Curso curso) async {
    if (curso.ativo) {
      final confirmou = await confirmarDesativacao(context, curso);
      if (!confirmou || !mounted) return;

      setState(() => CursoService.definirAtivo(curso.id, false));
      _avisar('Curso "${curso.nome}" desativado.');
    } else {
      setState(() => CursoService.definirAtivo(curso.id, true));
      _avisar('Curso "${curso.nome}" reativado.');
    }
  }

  Future<void> _abrir(Curso curso) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaCurso(cursoId: curso.id)),
    );

    // A tela do curso pode ter editado ou desativado o curso.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cursos = CursoService.cursos;

    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
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
                          child: const Icon(Icons.add, color: _azul, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (cursos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Nenhum curso cadastrado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 14,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                )
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
          ),
        ),
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
