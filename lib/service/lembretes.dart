import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../model/horario.dart';
import '../model/reserva.dart';
import '../model/usuario.dart';
import 'agenda.dart';
import 'horario_service.dart';
import 'streams.dart';

/// Quando o lembrete de uma aula fixa deve tocar pela próxima vez: o começo do
/// turno menos [antecedencia], no próximo [dia] da semana a partir de [agora].
/// Se o horário desta semana já passou, vai para a semana que vem.
DateTime proximoLembrete(
  DiaSemana dia,
  Turno turno,
  DateTime agora, {
  Duration antecedencia = Lembretes.antecedencia,
}) {
  final inicio = turno.inicio;
  // DiaSemana.segunda é o índice 0 e DateTime.monday é 1.
  final diasAte = (dia.index + 1 - agora.weekday) % 7;
  final data = DateTime(agora.year, agora.month, agora.day + diasAte);
  var quando = DateTime(
    data.year,
    data.month,
    data.day,
    inicio.hora,
    inicio.minuto,
  ).subtract(antecedencia);
  if (!quando.isAfter(agora)) {
    quando = DateTime(
      quando.year,
      quando.month,
      quando.day + 7,
      quando.hour,
      quando.minute,
    );
  }
  return quando;
}

/// Lembretes locais das aulas da grade (RF008/UC005, versão sem servidor).
///
/// O celular agenda, ele mesmo, uma notificação [antecedencia] antes de cada
/// aula fixa da pessoa, repetindo toda semana. Funciona com o app fechado e
/// sem internet, porque o agendamento fica no aparelho.
///
/// - Professor: aulas das disciplinas em que dá aula.
/// - Aluno: aulas das disciplinas em que está matriculado.
/// - Administrador: nenhum lembrete.
///
/// Só no Android: no navegador não existe agendamento com o app fechado.
/// Reservas (trocas de sala, aulas extras) não geram lembrete; o lembrete diz a
/// sala da grade.
class Lembretes {
  Lembretes._();

  static const Duration antecedencia = Duration(minutes: 30);

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _pronto = false;
  static StreamSubscription<List<Horario>>? _assinatura;

  static bool get suportado =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> _inicializar() async {
    if (_pronto) return;
    tzdata.initializeTimeZones();
    // O app é do IFFar (Brasil). O horário de Brasília não tem mais horário de
    // verão, então o mesmo fuso vale o ano todo.
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _pronto = true;
  }

  /// Começa a manter os lembretes de [usuario]: agenda agora e reagenda sempre
  /// que a grade ou as disciplinas dele mudarem. Chamado depois do login.
  static Future<void> iniciarPara(Usuario usuario) async {
    await parar();
    if (!suportado) return;

    try {
      await _inicializar();
      // Android 13+: pede a permissão de mostrar notificações (uma vez).
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Lembretes indisponíveis: $e');
      return;
    }

    _assinatura =
        trocarPara(
          disciplinaIdsDe(usuario),
          HorarioService.instancia.dasDisciplinas,
        ).listen(
          (aulas) => unawaited(_reagendar(aulas)),
          // Sem conexão, os lembretes já agendados continuam valendo.
          onError: (Object e) => debugPrint('Lembretes: $e'),
        );
  }

  /// Para de atualizar e apaga os lembretes agendados (ao sair da conta: o
  /// próximo a entrar no aparelho não deve receber as aulas do anterior).
  static Future<void> parar() async {
    await _assinatura?.cancel();
    _assinatura = null;
    if (suportado && _pronto) await _plugin.cancelAll();
  }

  static Future<void> _reagendar(List<Horario> aulas) async {
    await _plugin.cancelAll();

    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'lembretes_aula',
        'Lembretes de aula',
        channelDescription: 'Aviso 30 minutos antes de cada aula da grade.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final agora = DateTime.now();
    for (var i = 0; i < aulas.length; i++) {
      final aula = aulas[i];
      final quando = proximoLembrete(aula.dia, aula.turno, agora);
      final inicio = aula.turno.inicio;
      final hora =
          '${inicio.hora.toString().padLeft(2, '0')}:'
          '${inicio.minuto.toString().padLeft(2, '0')}';

      await _plugin.zonedSchedule(
        id: i,
        scheduledDate: tz.TZDateTime(
          tz.local,
          quando.year,
          quando.month,
          quando.day,
          quando.hour,
          quando.minute,
        ),
        notificationDetails: detalhes,
        // Inexato: o Android pode atrasar alguns minutos para poupar bateria,
        // sem exigir a permissão especial de alarme exato.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repete toda semana no mesmo dia e horário.
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        title: 'Aula em 30 minutos',
        body:
            '${aula.disciplinaNome} às $hora • '
            '${aula.sala.rotuloCurto} ${aula.sala.numero}',
      );
    }
  }
}
