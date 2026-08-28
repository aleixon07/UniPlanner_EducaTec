import 'package:flutter/material.dart';

import 'principal.dart';
import 'salas.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF3750B5)),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Tela Principal'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaInicial()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Reserva de Salas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Salas()),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
