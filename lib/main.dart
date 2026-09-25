import 'package:flutter/material.dart';

import 'splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Sem isto o Material 3 pinta os dialogs com um tom rosado,
        // que vem da paleta roxa padrão do Flutter.
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      home: const Splash(),
    );
  }
}
