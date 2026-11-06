import 'package:flutter/material.dart';

import '../model/sala.dart';
import '../service/sala_service.dart';
import '../sidebar.dart';
import '../usuario/widgets_sala.dart';
import 'dialog_sala.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

/// Gerenciamento de salas do administrador.
///
/// Mesmo visual da tela de reserva (filtros, grade e "Minhas Reservas"), mais
/// o cadastro: "Adicionar Sala" abre o [DialogSala]. Tocar numa sala abre a
/// reserva; segurar oferece a remoção. Os dados vêm do Firestore e a grade se
/// atualiza sozinha.
class GerenciarSalas extends StatefulWidget {
  const GerenciarSalas({super.key});

  @override
  State<GerenciarSalas> createState() => _GerenciarSalasState();
}

class _GerenciarSalasState extends State<GerenciarSalas> {
  late final Stream<List<Sala>> _salas = SalaService.instancia.listar();

  FiltroSala _filtro = FiltroSala.todos;
  bool _cadastrandoPadrao = false;

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: const TextStyle(fontFamily: 'NunitoSans'),
          ),
        ),
      );
  }

  Future<void> _adicionar() async {
    final descricao = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DialogSala(),
    );

    if (descricao == null || !mounted) return;
    _avisar('$descricao cadastrada.');
  }

  Future<void> _remover(Sala sala) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Remover sala?',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _azulEscuro,
          ),
        ),
        content: Text(
          '${sala.descricao} vai sair da lista e não poderá mais ser '
          'reservada.',
          style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
              'Remover',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      await SalaService.instancia.remover(sala);
      if (!mounted) return;
      _avisar('${sala.descricao} removida.');
    } on ErroSala catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    }
  }

  Future<void> _cadastrarPadrao() async {
    setState(() => _cadastrandoPadrao = true);
    try {
      await SalaService.instancia.cadastrarPadrao();
      if (!mounted) return;
      _avisar('Salas padrão cadastradas.');
    } on ErroSala catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    } finally {
      if (mounted) setState(() => _cadastrandoPadrao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ============================================================
          // CABEÇALHO + FILTRO + GRADE
          // ============================================================
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                children: [
                  const Text(
                    'Gerenciamento de Salas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _azulEscuro,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _BotaoAdicionar(onTap: _adicionar),

                  const SizedBox(height: 8),

                  FiltrosSala(
                    selecionado: _filtro,
                    onChanged: (filtro) => setState(() => _filtro = filtro),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<List<Sala>>(
                      stream: _salas,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const MensagemSalas(
                            'Não foi possível carregar as salas. '
                            'Verifique a conexão e as regras do Firestore.',
                            cor: _vermelho,
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.data!.isEmpty) {
                          return _ListaVazia(
                            carregando: _cadastrandoPadrao,
                            onCadastrarPadrao: _cadastrarPadrao,
                          );
                        }

                        final visiveis = filtrarSalas(snapshot.data!, _filtro);
                        if (visiveis.isEmpty) {
                          return const MensagemSalas(
                            'Nenhum ambiente neste filtro.',
                          );
                        }

                        return GradeSalas(
                          salas: visiveis,
                          onTap: (sala) => reservarSala(context, sala),
                          onLongPress: _remover,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Toque para reservar • segure para remover',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 12,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // MINHAS RESERVAS
          // ============================================================
          const Expanded(flex: 4, child: PainelReservas()),
        ],
      ),
    );
  }
}

// ================================================================
// "ADICIONAR SALA (+)" — igual ao do gerenciamento de usuários
// ================================================================
class _BotaoAdicionar extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoAdicionar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Adicionar Sala',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _azul,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE3E8F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: _azul, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LISTA VAZIA: oferece cadastrar as salas que já existiam no protótipo
// ================================================================
class _ListaVazia extends StatelessWidget {
  final bool carregando;
  final VoidCallback onCadastrarPadrao;

  const _ListaVazia({
    required this.carregando,
    required this.onCadastrarPadrao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nenhuma sala cadastrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                color: Color(0xFF7A7A7A),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: carregando ? null : onCadastrarPadrao,
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Cadastrar salas padrão (301–312 e labs)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
