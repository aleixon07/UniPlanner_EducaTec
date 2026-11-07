import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/curso.dart';
import '../model/semestre.dart';
import '../service/semestre_service.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Modal para mudar o número de um semestre. Adicionar não usa modal: o
/// semestre novo é criado direto, na tela do curso.
///
/// Salva ao confirmar e só fecha se der certo, devolvendo o número novo. Se
/// der erro (número repetido, sem conexão...), mostra a mensagem aqui mesmo.
/// `null` se cancelar.
class DialogSemestre extends StatefulWidget {
  final Semestre semestre;

  const DialogSemestre({super.key, required this.semestre});

  @override
  State<DialogSemestre> createState() => _DialogSemestreState();
}

class _DialogSemestreState extends State<DialogSemestre> {
  late final TextEditingController _numeroController;
  String? _erro;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: '${widget.semestre.numero}',
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final numero = int.tryParse(_numeroController.text.trim());

    if (numero == null ||
        numero < 1 ||
        numero > SemestreService.maximoPorCurso) {
      setState(
        () => _erro =
            'Informe um número de 1 a ${SemestreService.maximoPorCurso}.',
      );
      return;
    }

    setState(() {
      _erro = null;
      _salvando = true;
    });

    try {
      await SemestreService.instancia.renumerar(widget.semestre, numero);
      if (!mounted) return;
      Navigator.pop(context, numero);
    } on ErroSemestre catch (e) {
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
              const Text(
                'Editar Semestre',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _numeroController,
                enabled: !_salvando,
                autofocus: true,
                maxLength: 2,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _salvar(),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: InputDecoration(
                  labelText: 'Número do semestre',
                  hintText: '1 a ${SemestreService.maximoPorCurso}',
                  errorText: _erro,
                  errorMaxLines: 3,
                  counterText: '',
                  labelStyle: const TextStyle(fontFamily: 'NunitoSans'),
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

/// Alerta de confirmação antes de excluir um semestre. Devolve `true` se o
/// usuário confirmar.
Future<bool> confirmarExclusaoSemestre(
  BuildContext context,
  Semestre semestre,
  Curso curso,
) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Excluir semestre?',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _azulEscuro,
        ),
      ),
      content: Text(
        'O ${semestre.rotulo} e todas as disciplinas dele serão excluídos do '
        'curso "${curso.nome}". Esta ação não pode ser desfeita.',
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
