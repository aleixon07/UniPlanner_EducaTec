import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'senha/dialog_trocar_senha.dart';
import 'senha/recuperar_senha.dart';
import 'service/auth_service.dart';
import 'service/lembretes.dart';
import 'sidebar.dart';
import 'usuario/principal.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha o e-mail e a senha.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final usuario = await AuthService.entrar(email: email, senha: senha);
      if (!mounted) return;

      // Primeiro acesso: só entra depois de trocar a senha temporária.
      if (usuario.senhaTemporaria) {
        final trocou = await abrirTrocaDeSenha(context, senhaTemporaria: senha);
        if (!trocou) {
          await AuthService.sair();
          if (!mounted) return;
          setState(() => _carregando = false);
          return;
        }
        if (!mounted) return;
      }

      // Agenda os lembretes de aula deste usuário (não precisa esperar).
      unawaited(Lembretes.iniciarPara(usuario));

      _senhaController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaInicial()),
      );
    } on ErroAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (e) {
      // Rede caindo no meio, Firebase não inicializado, qualquer imprevisto:
      // sem isto o botão ficaria travado em "carregando" para sempre.
      if (!mounted) return;
      setState(() {
        _erro = 'Erro inesperado ao entrar. Tente novamente.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),

      // Rola quando o teclado abre, para o botão Entrar nunca ficar escondido.
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 50),
                      const Text(
                        'Seja Bem-Vindo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NunitoSans',
                        ),
                      ),

                      const SizedBox(height: 25),

                      Image.asset('assets/logo.png', width: 120),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _emailController,
                          enabled: !_carregando,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            hintText: 'Digite seu e-mail',
                            labelStyle: const TextStyle(
                              fontFamily: 'NunitoSans',
                            ),
                            hintStyle: const TextStyle(
                              fontFamily: 'NunitoSans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _senhaController,
                          enabled: !_carregando,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Digite sua senha',
                            labelStyle: const TextStyle(
                              fontFamily: 'NunitoSans',
                            ),
                            hintStyle: const TextStyle(
                              fontFamily: 'NunitoSans',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),

                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 300,
                          child: Text(
                            _erro!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE23B3B),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      LinkText(
                        titulo: 'Esqueceu sua senha? Clique aqui!',
                        telaDestino: RecuperarSenha(),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3750B5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(fontFamily: 'NunitoSans'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class LinkText extends StatelessWidget {
  final String titulo;
  final Widget telaDestino;

  const LinkText({super.key, required this.titulo, required this.telaDestino});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.grey, fontSize: 13),
        children: [
          TextSpan(
            text: titulo,
            style: const TextStyle(
              color: Color(0xFF3750B5),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => telaDestino),
                );
              },
          ),
        ],
      ),
    );
  }
}
