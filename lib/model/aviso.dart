import 'package:flutter/material.dart';

/// Aviso/anotação criado pelo usuário em uma data da agenda (UC008).
///
/// Fica na coleção `avisos` do Firestore, com id automático. É pessoal: cada
/// pessoa vê só os avisos que ela criou ([autorId]).
class Aviso {
  final String id;
  final String autorId;
  final String titulo;
  final String descricao;
  final DateTime data;
  final TimeOfDay hora;
  final Color cor;

  const Aviso({
    this.id = '',
    this.autorId = '',
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.hora,
    required this.cor,
  });

  /// Dia no formato `2026-11-06` (texto, para não depender de fuso horário).
  static String chaveDia(DateTime dia) {
    final m = dia.month.toString().padLeft(2, '0');
    final d = dia.day.toString().padLeft(2, '0');
    return '${dia.year}-$m-$d';
  }

  Map<String, Object?> toMap() => {
    'autorId': autorId,
    'titulo': titulo,
    'descricao': descricao,
    'dia': chaveDia(data),
    'hora': hora.hour * 60 + hora.minute,
    'cor': cor.toARGB32(),
  };

  /// Devolve `null` se o documento estiver incompleto, para um dado estragado
  /// não derrubar a tela.
  static Aviso? fromMap(String id, Map<String, dynamic> dados) {
    final partes = ((dados['dia'] as String?) ?? '').split('-');
    if (partes.length != 3) return null;
    final ano = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final dia = int.tryParse(partes[2]);
    if (ano == null || mes == null || dia == null) return null;

    final minutos = (dados['hora'] as num?)?.toInt() ?? 0;
    return Aviso(
      id: id,
      autorId: (dados['autorId'] as String?) ?? '',
      titulo: (dados['titulo'] as String?) ?? '',
      descricao: (dados['descricao'] as String?) ?? '',
      data: DateTime(ano, mes, dia),
      hora: TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60),
      cor: Color(
        (dados['cor'] as num?)?.toInt() ?? coresAviso.first.toARGB32(),
      ),
    );
  }
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
