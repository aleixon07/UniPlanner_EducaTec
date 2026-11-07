import 'package:flutter/material.dart';

import '../model/sala.dart';
import '../service/sala_service.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

String? _validarNumero(String numero) {
  final valor = numero.trim();
  if (valor.isEmpty) return 'Informe o número.';
  // Vira parte do id do documento no Firestore, então nada de "/" ou espaços.
  if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(valor)) {
    return 'Use só letras, números e hífen.';
  }
  return null;
}

String? _validarAndar(String andar) {
  return andar.trim().isEmpty ? 'Informe o andar.' : null;
}

/// Modal para cadastrar uma sala ou laboratório: número, tipo e andar.
///
/// Salva ao confirmar e só fecha se der certo, devolvendo a descrição da sala
/// cadastrada. Se der erro, mostra a mensagem aqui mesmo.
class DialogSala extends StatefulWidget {
  const DialogSala({super.key});

  @override
  State<DialogSala> createState() => _DialogSalaState();
}

class _DialogSalaState extends State<DialogSala> {
  final _numeroController = TextEditingController();
  final _andarController = TextEditingController();

  TipoSala _tipo = TipoSala.sala;

  // Enquanto o usuário não mexer no andar, ele é sugerido pelo número:
  // "308" -> "3º Andar".
  bool _andarEditado = false;

  String? _erroNumero;
  String? _erroAndar;
  String? _erroGeral;
  bool _salvando = false;

  @override
  void dispose() {
    _numeroController.dispose();
    _andarController.dispose();
    super.dispose();
  }

  void _sugerirAndar(String numero) {
    if (_andarEditado) return;
    final primeiro = numero.trim().isEmpty ? '' : numero.trim()[0];
    _andarController.text = RegExp(r'[0-9]').hasMatch(primeiro)
        ? '$primeiroº Andar'
        : '';
  }

  Future<void> _cadastrar() async {
    final numero = _numeroController.text.trim();
    final andar = _andarController.text.trim();

    setState(() {
      _erroNumero = _validarNumero(numero);
      _erroAndar = _validarAndar(andar);
      _erroGeral = null;
    });

    if (_erroNumero != null || _erroAndar != null) return;

    setState(() => _salvando = true);

    try {
      await SalaService.instancia.cadastrar(
        numero: numero,
        tipo: _tipo,
        andar: andar,
      );
      if (!mounted) return;
      final sala = Sala(
        numero: numero.toUpperCase(),
        tipo: _tipo,
        andar: andar,
      );
      Navigator.pop(context, sala.descricao);
    } on ErroSala catch (e) {
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _salvando = false;
      });
    } catch (_) {
      // Qualquer imprevisto: sem isto o botão ficaria travado em "salvando".
      if (!mounted) return;
      setState(() {
        _erroGeral = 'Erro inesperado ao cadastrar. Tente novamente.';
        _salvando = false;
      });
    }
  }

  InputDecoration _decoracao(String dica, {String? erro}) {
    return InputDecoration(
      hintText: dica,
      errorText: erro,
      hintStyle: const TextStyle(
        fontFamily: 'NunitoSans',
        color: Color(0xFF9E9E9E),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                'Adicionar Sala',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),

              const SizedBox(height: 16),

              // TIPO
              Row(
                children: [
                  Expanded(
                    child: _BotaoTipo(
                      texto: 'Sala de Aula',
                      selecionado: _tipo == TipoSala.sala,
                      onTap: _salvando
                          ? null
                          : () => setState(() => _tipo = TipoSala.sala),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BotaoTipo(
                      texto: 'Laboratório',
                      selecionado: _tipo == TipoSala.laboratorio,
                      onTap: _salvando
                          ? null
                          : () => setState(() => _tipo = TipoSala.laboratorio),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _numeroController,
                enabled: !_salvando,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onChanged: _sugerirAndar,
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: _decoracao('Número (ex.: 308)', erro: _erroNumero),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _andarController,
                enabled: !_salvando,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _andarEditado = true,
                onSubmitted: (_) => _cadastrar(),
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: _decoracao(
                  'Andar (ex.: 3º Andar)',
                  erro: _erroAndar,
                ),
              ),

              if (_erroGeral != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erroGeral!,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _vermelho,
                  ),
                ),
              ],

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
                      onPressed: _salvando ? null : _cadastrar,
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
                              'Cadastrar',
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

class _BotaoTipo extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback? onTap;

  const _BotaoTipo({
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? _azul : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? _azul : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(
          texto,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selecionado ? Colors.white : _azulEscuro,
          ),
        ),
      ),
    );
  }
}
