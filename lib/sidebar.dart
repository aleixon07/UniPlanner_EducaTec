import 'package:flutter/material.dart';

import 'usuario/principal.dart';
import 'usuario/reservar_sala.dart';
import 'usuario/salas.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool usuariosAberto = true;
  bool salasAberto = true;

  final Color azul = const Color(0xFF3750B5);
  final Color azulSelecionado = const Color(0xFF5A70C7);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 240,
      backgroundColor: azul,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: [
            // =========================
            // TELA PRINCIPAL
            // =========================

            _itemMenu(
              titulo: 'Tela Principal',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaInicial()),
                );
              },
            ),

            const SizedBox(height: 4),

            // =========================
            // RESERVAR SALA
            // =========================
            _itemMenu(
              titulo: 'Reservar Sala',
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReservarSala()),
                );
              },
            ),

            const SizedBox(height: 4),

            // =========================
            // GERENCIAR USUÁRIOS
            // =========================
            _itemExpandivel(
              titulo: 'Gerenciar Usuários',
              aberto: usuariosAberto,
              onTap: () {
                setState(() {
                  usuariosAberto = !usuariosAberto;
                });
              },
            ),

            if (usuariosAberto) ...[
              _subItem(
                titulo: 'Aluno',
                onTap: () {
                  // TODO: abrir tela de alunos
                },
              ),

              _subItem(
                titulo: 'Professor',
                onTap: () {
                  // TODO: abrir tela de professores
                },
              ),
            ],

            const SizedBox(height: 4),

            // =========================
            // GERENCIAR SALAS
            // =========================
            _itemExpandivel(
              titulo: 'Gerenciar Salas',
              aberto: salasAberto,
              onTap: () {
                setState(() {
                  salasAberto = !salasAberto;
                });
              },
            ),

            if (salasAberto) ...[
              _subItem(
                titulo: 'Salas',
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Salas()),
                  );
                },
              ),

              _subItem(
                titulo: 'Reservas',
                onTap: () {
                  // TODO: abrir tela de reservas
                },
              ),
            ],

            const SizedBox(height: 20),

            // =========================
            // ADICIONAR MATERIAS
            // =========================
            _itemMenu(
              titulo: 'Adicionar Materias',
              onTap: () {
                // TODO: abrir tela de matérias
              },
            ),

            const SizedBox(height: 4),

            // =========================
            // TROCAR DE CURSO
            // =========================
            _itemMenu(
              titulo: 'Trocar de Curso',
              onTap: () {
                // TODO: abrir tela de troca de curso
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM NORMAL
  // ============================================================

  Widget _itemMenu({required String titulo, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // ITEM EXPANSÍVEL
  // ============================================================

  Widget _itemExpandivel({
    required String titulo,
    required bool aberto,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        // O fundo precisa vir de um Material, e não de um BoxDecoration:
        // senão o ListTile pinta o splash atrás da cor e o toque some.
        child: Material(
          color: azulSelecionado,
          borderRadius: BorderRadius.circular(5),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 16, right: 12),
            title: Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            trailing: Icon(
              aberto ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 25,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBITEM
  // ============================================================

  Widget _subItem({required String titulo, required VoidCallback onTap}) {
    return SizedBox(
      height: 36,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 49, right: 16),
        title: Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ================================================================
// APP BAR
// ================================================================

class AppBarUniPlanner extends StatelessWidget implements PreferredSizeWidget {
  const AppBarUniPlanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Align(
        alignment: Alignment.centerRight,
        child: Text('UniPlanner', style: TextStyle(fontFamily: 'Offside')),
      ),
      backgroundColor: const Color(0xFF3750B5),
      foregroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
