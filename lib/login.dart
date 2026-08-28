import 'package:flutter/material.dart';

import 'principal.dart';
import 'sidebar.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),

      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seja Bem-Vindo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Itim',
                      ),
                    ),

                    const SizedBox(height: 25),

                    Image.asset('assets/logo.png', width: 120),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'CPF',
                          hintText: 'Digite seu CPF',
                          labelStyle: const TextStyle(fontFamily: 'Itim'),
                          hintStyle: const TextStyle(fontFamily: 'Itim'),
                          filled: true,
                          fillColor: const Color(0xFFE8E8E8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: 400,
                      child: TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Digite sua senha',
                          labelStyle: const TextStyle(fontFamily: 'Itim'),
                          hintStyle: const TextStyle(fontFamily: 'Itim'),
                          filled: true,
                          fillColor: const Color(0xFFE8E8E8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Esqueceu sua senha? Clique aqui!',
                        style: TextStyle(
                          fontFamily: 'Itim',
                          color: Colors.black,
                        ),
                      ),
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
                        style: TextStyle(fontFamily: 'Itim'),
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
