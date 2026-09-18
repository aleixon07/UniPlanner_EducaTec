import 'package:flutter/material.dart';

import 'sidebar.dart';

class Salas extends StatelessWidget {
  const Salas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),
      drawer: const Sidebar(),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: const Center(child: Text('salas')),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: const Center(child: Text('reservas')),
            ),
          ),
        ],
      ),
    );
  }
}
