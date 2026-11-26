import 'dart:async';

import 'package:flutter/material.dart';

import 'login.dart';
import 'service/auth_service.dart';
import 'service/lembretes.dart';
import 'usuario/principal.dart';

/// Tela de abertura do app.
///
/// A animação acontece em três momentos, todos controlados pelo mesmo
/// [AnimationController]:
///   1. a tela começa totalmente azul;
///   2. o fundo clareia até o branco enquanto a logo aparece crescendo;
///   3. a logo fica parada um instante e o app vai para o login.
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  static const Color _azul = Color(0xFF3750B5);

  late final AnimationController _controller;
  late final Animation<Color?> _corDeFundo;
  late final Animation<double> _opacidadeLogo;
  late final Animation<double> _escalaLogo;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Fundo: fica azul no começo e clareia até o branco.
    _corDeFundo = ColorTween(begin: _azul, end: Colors.white).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeInOut),
      ),
    );

    // Logo: aparece junto com o clareamento do fundo.
    _opacidadeLogo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.70, curve: Curves.easeIn),
    );

    _escalaLogo = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward().whenComplete(_proximaTela);
  }

  /// Depois da animação: quem já está logado neste aparelho vai direto para a
  /// tela principal, de qualquer perfil. Os demais vão para o login.
  Future<void> _proximaTela() async {
    if (!mounted) return;

    final usuario = await AuthService.restaurarSessao();
    if (!mounted) return;

    if (usuario != null) {
      // Os lembretes de aula também precisam voltar a ser agendados.
      unawaited(Lembretes.iniciarPara(usuario));
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            usuario != null ? const TelaInicial() : const Login(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _corDeFundo.value,
          body: Center(
            child: Opacity(
              opacity: _opacidadeLogo.value,
              child: Transform.scale(scale: _escalaLogo.value, child: child),
            ),
          ),
        );
      },
      // Fica fora do builder para a imagem não ser reconstruída a cada frame.
      child: Image.asset('assets/logo.png', width: 160),
    );
  }
}
