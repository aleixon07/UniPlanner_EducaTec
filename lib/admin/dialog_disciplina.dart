import 'package:flutter/material.dart';

import '../model/disciplina.dart';
import '../service/disciplina_service.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Modal para mudar o nome de uma disciplina. Adicionar não usa modal: é um
/// campo direto dentro do semestre.
///
/// Salva ao confirmar e só fecha se der certo, devolvendo o nome novo. Em caso
/// de erro mostra a mensagem aqui mesmo. `null` se cancelar.
class DialogDisciplina extends StatefulWidget {
  final Disciplina disciplina;

  const DialogDisciplina({super.key, required this.disciplina});

  @override
  State<DialogDisciplina> createState() => _DialogDisciplinaState();
}

class _DialogDisciplinaState extends State<DialogDisciplina> {
  late final TextEditingController _nomeController = TextEditingController(
    text: widget.disciplina.nome,
  );
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _erro = null;
      _salvando = true;
    });

    try {
      await DisciplinaService.instancia.editar(
        widget.disciplina,
        _nomeController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, _nomeController.text.trim());
    } on ErroDisciplina catch (e) {
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
              const Text(
                'Editar Disciplina',
                style: TextStyle(
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
                maxLength: FirebaseDisciplinaService.tamanhoMaximoNome,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _salvar(),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: InputDecoration(
                  labelText: 'Nome da disciplina',
                  errorText: _erro,
                  errorMaxLines: 3,
                  counterText: '',
                  labelStyle: const TextStyle(fontFamily: 'NunitoSans'),
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
                          : const Text(
                              'Salvar',
                              overflow: TextOverflow.ellipsis,
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

/// Alerta de confirmação antes de excluir uma disciplina. Devolve `true` se o
/// usuário confirmar.
Future<bool> confirmarExclusaoDisciplina(
  BuildContext context,
  Disciplina disciplina,
) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Excluir disciplina?',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _azulEscuro,
        ),
      ),
      content: Text(
        'A disciplina "${disciplina.nome}" será excluída. '
        'Esta ação não pode ser desfeita.',
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
            'Excluir',
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
