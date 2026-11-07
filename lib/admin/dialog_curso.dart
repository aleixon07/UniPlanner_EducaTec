import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../service/curso_service.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Modal para cadastrar um curso novo ou editar um existente.
///
/// Se [curso] for informado, o campo já vem preenchido e o modal funciona como
/// edição. Salva ao confirmar e só fecha se der certo, devolvendo o nome
/// salvo. Se der erro (nome repetido, sem permissão, sem conexão...), mostra a
/// mensagem aqui mesmo e mantém o que foi digitado. `null` se cancelar.
class DialogCurso extends StatefulWidget {
  final Curso? curso;

  const DialogCurso({super.key, this.curso});

  @override
  State<DialogCurso> createState() => _DialogCursoState();
}

class _DialogCursoState extends State<DialogCurso> {
  late final TextEditingController _nomeController;
  String? _erro;
  bool _salvando = false;

  bool get _editando => widget.curso != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.curso?.nome);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome do curso.');
      return;
    }

    setState(() {
      _erro = null;
      _salvando = true;
    });

    try {
      final curso = widget.curso;
      if (curso == null) {
        await CursoService.instancia.cadastrar(nome);
      } else {
        await CursoService.instancia.editar(curso.id, nome);
      }
      if (!mounted) return;
      Navigator.pop(context, nome);
    } on ErroCurso catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _salvando = false;
      });
    } catch (_) {
      // Qualquer imprevisto: sem isto o botão ficaria travado em "salvando".
      if (!mounted) return;
      setState(() {
        _erro = 'Erro inesperado ao salvar. Tente novamente.';
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto salva, não deixa fechar: a gravação continuaria rodando sem
    // ninguém para mostrar o resultado.
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
                _editando ? 'Editar Curso' : 'Cadastrar Curso',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _nomeController,
                enabled: !_salvando,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _salvar(),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: InputDecoration(
                  hintText: 'Nome do curso',
                  errorText: _erro,
                  errorMaxLines: 3,
                  counterText: '',
                  hintStyle: const TextStyle(
                    fontFamily: 'NunitoSans',
                    color: Color(0xFF9E9E9E),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
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

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _salvando
                          ? null
                          : () => Navigator.pop(context),
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
                        overflow: TextOverflow.ellipsis,
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
                          : Text(
                              _editando ? 'Salvar' : 'Cadastrar',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
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

/// Alerta de confirmação antes de desativar um curso (UC011, fluxo A3).
/// Devolve `true` se o usuário confirmar.
Future<bool> confirmarDesativacao(BuildContext context, Curso curso) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Desativar curso?',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _azulEscuro,
        ),
      ),
      content: Text(
        'O curso "${curso.nome}" ficará inativo. '
        'Você poderá reativá-lo depois.',
        style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFE3E3E3),
            foregroundColor: const Color(0xFF4A4A4A),
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
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: _vermelho,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Desativar',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  return confirmou ?? false;
}
