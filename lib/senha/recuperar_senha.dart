import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import '../sidebar.dart';

/// Recuperar senha (UC002): a pessoa informa o e-mail e o Firebase envia um
/// link para criar uma senha nova.
///
/// O Firebase não gera código numérico; por isso o fluxo é por link, e não
/// pelas telas de código de 4 dígitos do protótipo.
class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  final TextEditingController _emailController = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }

    setState(() {
      _erro = null;
      _enviando = true;
    });
    try {
      await AuthService.enviarRedefinicaoDeSenha(email);
      if (mounted) setState(() => _enviado = true);
    } on ErroAuth catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: _enviado ? _confirmacao() : _formulario(),
      ),
    );
  }

  Widget _formulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        const Text(
          'Recuperar Senha',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Informe o seu e-mail. Vamos enviar um link para você criar uma '
          'senha nova.',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            color: Color(0xFF7A7A7A),
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          enabled: !_enviando,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _enviar(),
          decoration: InputDecoration(
            labelText: 'E-mail',
            hintText: 'Digite seu e-mail',
            errorText: _erro,
            hintStyle: const TextStyle(
              fontFamily: 'NunitoSans',
              color: Color(0xFF9E9E9E),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3750B5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enviar link',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: _voltar()),
      ],
    );
  }

  Widget _confirmacao() {
    return Column(
      children: [
        const SizedBox(height: 100),
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFF34A853),
          child: Icon(Icons.mark_email_read, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verifique seu e-mail',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Se ${_emailController.text.trim()} tiver uma conta, você vai '
          'receber um link para criar uma senha nova. Confira também a caixa '
          'de spam.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            color: Color(0xFF7A7A7A),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => setState(() => _enviado = false),
          child: const Text(
            'Não recebi / enviar de novo',
            style: TextStyle(fontFamily: 'NunitoSans'),
          ),
        ),
        _voltar(),
      ],
    );
  }

  Widget _voltar() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        'Voltar ao login',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3750B5),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF3750B5),
        ),
      ),
    );
  }
}
