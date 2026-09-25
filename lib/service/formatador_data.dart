import 'package:flutter/material.dart';

const List<String> _diasSemana = [
  'seg.',
  'ter.',
  'qua.',
  'qui.',
  'sex.',
  'sáb.',
  'dom.',
];

const List<String> _mesesAbreviados = [
  'jan.',
  'fev.',
  'mar.',
  'abr.',
  'mai.',
  'jun.',
  'jul.',
  'ago.',
  'set.',
  'out.',
  'nov.',
  'dez.',
];

/// Formata a data no padrão usado na agenda. Ex.: `qua., 10 de set.`
String formatarData(DateTime data) {
  return '${_diasSemana[data.weekday - 1]}, ${data.day} de '
      '${_mesesAbreviados[data.month - 1]}';
}

/// Formata a data em números. Ex.: `16/09/2026`
String formatarDataCurta(DateTime data) {
  final d = data.day.toString().padLeft(2, '0');
  final m = data.month.toString().padLeft(2, '0');
  return '$d/$m/${data.year}';
}

/// Formata a hora em 24h. Ex.: `08:00`
String formatarHora(TimeOfDay hora) {
  final h = hora.hour.toString().padLeft(2, '0');
  final m = hora.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
