import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import 'politica_senha.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Modal obrigatório do primeiro login: troca a senha temporária por uma nova.
///
/// Não fecha tocando fora nem com o botão voltar. As saídas são "Salvar"
/// (devolve `true`) ou "Sair" (devolve `false`, e quem chamou encerra a
/// sessão). [senhaTemporaria] é a senha que acabou de ser usada no login.
///
/// Abra com [abrirTrocaDeSenha].
class DialogTrocarSenha extends StatefulWidget {
  final String senhaTemporaria;

  const DialogTrocarSenha({super.key, required this.senhaTemporaria});

  @override
  State<DialogTrocarSenha> createState() => _DialogTrocarSenhaState();
}

/// Mostra o [DialogTrocarSenha] e devolve `true` se a senha foi trocada.
Future<bool> abrirTrocaDeSenha(
  BuildContext context, {
  required String senhaTemporaria,
}) async {
  final trocou = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DialogTrocarSenha(senhaTemporaria: senhaTemporaria),
  );
  return trocou ?? false;
}

class _DialogTrocarSenhaState extends State<DialogTrocarSenha> {
  final _novaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  String? _erroNova;
  String? _erroConfirmacao;
  String? _erroGeral;
  bool _visivel = false;
  bool _salvando = false;

  @override
  void dispose() {
    _novaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nova = _novaController.text;
    final confirmacao = _confirmacaoController.text;

    String? erroNova = validarSenha(nova);
    if (erroNova == null && nova == widget.senhaTemporaria) {
      erroNova = 'A nova senha precisa ser diferente da temporária.';
    }

    setState(() {
      _erroNova = erroNova;
      _erroConfirmacao = nova == confirmacao ? null : 'As senhas não conferem.';
      _erroGeral = null;
    });
    if (_erroNova != null || _erroConfirmacao != null) return;

    setState(() => _salvando = true);
    try {
      await AuthService.trocarSenhaTemporaria(
        atual: widget.senhaTemporaria,
        nova: nova,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ErroAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _salvando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroGeral = 'Erro inesperado ao trocar a senha. Tente novamente.';
        _salvando = false;
      });
    }
  }

  InputDecoration _decoracao(String rotulo, String? erro) {
    return InputDecoration(
      labelText: rotulo,
      errorText: erro,
      errorMaxLines: 3,
      labelStyle: const TextStyle(fontFamily: 'NunitoSans'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      suffixIcon: IconButton(
        tooltip: _visivel ? 'Ocultar senha' : 'Mostrar senha',
        icon: Icon(
          _visivel ? Icons.visibility_off : Icons.visibility,
          size: 20,
        ),
        onPressed: () => setState(() => _visivel = !_visivel),
      ),
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
    // Nunca fecha sozinho: só por "Salvar" ou "Sair".
    return PopScope(
      canPop: false,
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
                'Crie sua senha',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Este é o seu primeiro acesso. Troque a senha temporária por '
                'uma senha só sua para continuar.',
                style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _novaController,
                enabled: !_salvando,
                autofocus: true,
                obscureText: !_visivel,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: _decoracao('Nova senha', _erroNova),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmacaoController,
                enabled: !_salvando,
                obscureText: !_visivel,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _salvar(),
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: _decoracao(
                  'Confirme a nova senha',
                  _erroConfirmacao,
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
                          : () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE3E3E3),
                        foregroundColor: const Color(0xFF4A4A4A),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Sair',
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
