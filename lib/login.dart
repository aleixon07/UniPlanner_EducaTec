import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'principal.dart';
import 'sidebar.dart';
import 'recuperar_senha.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),

      body: Column(
        children: [
          Center(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height:50),
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
                        decoration: InputDecoration(
                          labelText: 'CPF',
                          hintText: 'Digite seu CPF',
                          labelStyle: const TextStyle(fontFamily: 'NunitoSans'),
                          hintStyle: const TextStyle(fontFamily: 'NunitoSans'),
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
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Digite sua senha',
                          labelStyle: const TextStyle(fontFamily: 'NunitoSans'),
                          hintStyle: const TextStyle(fontFamily: 'NunitoSans'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),

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
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TelaInicial(),
                          ),
                        );
                      },
                      child: const Text(
                        'Entrar',
                        style: TextStyle(fontFamily: 'NunitoSans'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(flex: 1, child: Container(color: Colors.white)),
        ],
      ),
    );
  }
}

class LinkText extends StatelessWidget {
  final String titulo;
  final Widget telaDestino; 

  const LinkText({
    super.key, 
    required this.titulo, 
    required this.telaDestino,
  });

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