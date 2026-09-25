import 'package:flutter/material.dart';

/// Aviso/anotação criado pelo usuário em uma data da agenda.
class Aviso {
  final String titulo;
  final String descricao;
  final DateTime data;
  final TimeOfDay hora;
  final Color cor;

  const Aviso({
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.hora,
    required this.cor,
  });
}

/// Cores disponíveis para marcar um aviso.
const List<Color> coresAviso = [
  Color(0xFFE85D75),
  Color(0xFFF2994A),
  Color(0xFFF2C94C),
  Color(0xFF27AE60),
  Color(0xFF2D9CDB),
  Color(0xFF3750B5),
  Color(0xFF9B51E0),
  Color(0xFF7A7A7A),
];
