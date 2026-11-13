import 'package:flutter/material.dart';

import 'admin/gerenciar_cursos.dart';
import 'admin/gerenciar_matriculas.dart';
import 'admin/gerenciar_reservas.dart';
import 'admin/gerenciar_salas.dart';
import 'admin/gerenciar_usuarios.dart';
import 'login.dart';
import 'model/usuario.dart';
import 'service/auth_service.dart';
import 'service/sessao.dart';
import 'usuario/principal.dart';
import 'usuario/reservar_sala.dart';
import 'usuario/tela_matricula.dart';

/// Menu lateral. Os itens dependem do perfil de quem está logado (RF002):
/// aluno e professor veem a agenda e a reserva de salas; só o administrador
/// vê a área administrativa (cursos, usuários e salas).
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

  void _abrir(Widget tela) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => tela));
  }

  Future<void> _sair() async {
    final navigator = Navigator.of(context);
    await AuthService.sair();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (rota) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Sessao.usuario;
    final admin = Sessao.ehAdmin;

    return Drawer(
      width: 240,
      backgroundColor: azul,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: [
                  // QUEM ESTÁ LOGADO
                  if (usuario != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.nome,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            usuario.perfil.rotulo,
                            style: const TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                  _itemMenu(
                    titulo: 'Tela Principal',
                    onTap: () => _abrir(const TelaInicial()),
                  ),

                  const SizedBox(height: 4),

                  _itemMenu(
                    titulo: 'Reservar Sala',
                    onTap: () => _abrir(const ReservarSala()),
                  ),

                  // MATRÍCULA: só alunos.
                  if (Sessao.ehAluno) ...[
                    const SizedBox(height: 4),
                    _itemMenu(
                      titulo: 'Matrícula',
                      onTap: () => _abrir(const TelaMatricula()),
                    ),
                  ],

                  // ÁREA ADMINISTRATIVA: só administradores.
                  if (admin) ...[
                    const SizedBox(height: 4),

                    _itemMenu(
                      titulo: 'Admin',
                      onTap: () => _abrir(const GerenciarCursos()),
                    ),

                    const SizedBox(height: 4),

                    _itemMenu(
                      titulo: 'Período de Matrícula',
                      onTap: () => _abrir(const GerenciarMatriculas()),
                    ),

                    const SizedBox(height: 4),

                    _itemExpandivel(
                      titulo: 'Gerenciar Usuários',
                      aberto: usuariosAberto,
                      onTap: () =>
                          setState(() => usuariosAberto = !usuariosAberto),
                    ),

                    if (usuariosAberto) ...[
                      for (final perfil in PerfilUsuario.values)
                        _subItem(
                          titulo: perfil.rotulo,
                          onTap: () =>
                              _abrir(GerenciarUsuarios(perfil: perfil)),
                        ),
                    ],

                    const SizedBox(height: 4),

                    _itemExpandivel(
                      titulo: 'Gerenciar Salas',
                      aberto: salasAberto,
                      onTap: () => setState(() => salasAberto = !salasAberto),
                    ),

                    if (salasAberto) ...[
                      _subItem(
                        titulo: 'Salas',
                        onTap: () => _abrir(const GerenciarSalas()),
                      ),

                      _subItem(
                        titulo: 'Reservas',
                        onTap: () => _abrir(const GerenciarReservas()),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // SAIR
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                'Sair',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              onTap: _sair,
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
  /// Mostra o selo "ADMIN" ao lado do menu, nas telas da área administrativa.
  final bool admin;

  const AppBarUniPlanner({super.key, this.admin = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          if (admin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF5A70C7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          const Spacer(),
          const Text('UniPlanner', style: TextStyle(fontFamily: 'Offside')),
        ],
      ),
      backgroundColor: const Color(0xFF3750B5),
      foregroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
