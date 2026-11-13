import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../service/curso_service.dart';

/// Select para escolher o curso de um aluno. Opcional: "Sem curso" deixa o
/// aluno sem vínculo.
///
/// Lista os cursos ativos. Se o aluno já está num curso que foi desativado, esse
/// curso continua aparecendo (marcado como inativo), para a edição não apagar o
/// vínculo sem o administrador perceber.
class SelectCurso extends StatefulWidget {
  /// Curso atualmente escolhido (id), ou `null`.
  final String? valor;
  final bool habilitado;
  final ValueChanged<String?> onChanged;

  const SelectCurso({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  @override
  State<SelectCurso> createState() => _SelectCursoState();
}

class _SelectCursoState extends State<SelectCurso> {
  // Criado uma vez só, para o build não abrir conexões novas.
  late final Stream<List<Curso>> _cursos = CursoService.instancia.listar();

  InputDecoration _decoracao() {
    return InputDecoration(
      labelText: 'Curso (opcional)',
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
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Curso>>(
      stream: _cursos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Não foi possível carregar os cursos.',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 13,
              color: Color(0xFFE23B3B),
            ),
          );
        }

        final todos = snapshot.data;
        if (todos == null) {
          return InputDecorator(
            decoration: _decoracao(),
            child: const SizedBox(
              height: 20,
              width: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final opcoes = todos
            .where((c) => c.ativo || c.id == widget.valor)
            .toList();

        // O valor só vale se for mesmo uma das opções; o select quebra se
        // receber um valor que não está na lista (curso apagado, por exemplo).
        final valor = opcoes.any((c) => c.id == widget.valor)
            ? widget.valor
            : null;

        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: valor,
          dropdownColor: Colors.white,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Sem curso',
                style: TextStyle(fontFamily: 'NunitoSans'),
              ),
            ),
            for (final curso in opcoes)
              DropdownMenuItem<String?>(
                value: curso.id,
                child: Text(
                  curso.ativo ? curso.nome : '${curso.nome} (inativo)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'NunitoSans'),
                ),
              ),
          ],
          onChanged: widget.habilitado ? widget.onChanged : null,
          decoration: _decoracao(),
        );
      },
    );
  }
}
