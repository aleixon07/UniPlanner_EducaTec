import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../service/curso_service.dart';
import '../sidebar.dart';
import 'dialog_curso.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);
const Color _verde = Color(0xFF27AE60);

/// Tela de um curso: mostra os dados e permite editar e desativar/reativar.
///
/// Recebe só o [cursoId] e busca o curso no serviço a cada build, assim a tela
/// sempre mostra o dado atual depois de uma edição.
class TelaCurso extends StatefulWidget {
  final String cursoId;

  const TelaCurso({super.key, required this.cursoId});

  @override
  State<TelaCurso> createState() => _TelaCursoState();
}

class _TelaCursoState extends State<TelaCurso> {
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

              // AÇÕES
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
            ],
          ),
        ),
      ),
    );
  }
}

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
