import 'package:flutter/material.dart';

import 'sidebar.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

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
              child: const Center(child: Text('calendario')),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: const Center(child: Text('avisos')),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: const Center(child: Text('aulas do dia')),
            ),
          ),
        ],
      ),
    );
  }
}
