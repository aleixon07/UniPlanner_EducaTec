import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../model/aviso.dart';
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

/// Lembretes locais do app (RF008/UC005, versão sem servidor).
///
/// Dois tipos de notificação, com ids separados para não se atrapalharem:
/// - **Aulas da grade:** o celular avisa [antecedencia] antes de cada aula
///   fixa da pessoa, repetindo toda semana.
/// - **Avisos da agenda:** avisa no dia e horário marcados, uma vez só.
///
/// Os dois funcionam com o app fechado e sem internet, porque o agendamento
/// fica no aparelho.
///
/// Só no Android: no navegador não existe agendamento com o app fechado.
/// Reservas (trocas de sala, aulas extras) não geram lembrete de aula; o
/// lembrete diz a sala da grade.
class Lembretes {
  Lembretes._();

  static const Duration antecedencia = Duration(minutes: 30);

  /// Ids das aulas vão de 0 a 99999; os dos avisos começam aqui.
  static const int _baseAvisos = 100000;

  static const AndroidNotificationDetails _detalhesAulas =
      AndroidNotificationDetails(
        'lembretes_aula',
        'Lembretes de aula',
        channelDescription: 'Aviso 30 minutos antes de cada aula da grade.',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const AndroidNotificationDetails _detalhesAvisos =
      AndroidNotificationDetails(
        'avisos_agenda',
        'Avisos da agenda',
        channelDescription: 'Avisos criados na agenda, no horário marcado.',
        importance: Importance.high,
        priority: Priority.high,
      );

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _pronto = false;
  static StreamSubscription<List<Horario>>? _assinatura;

  static bool get suportado =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Id da notificação de um aviso. Estável: o mesmo aviso sempre tem o mesmo
  /// id, então dá para cancelá-lo depois.
  static int idDoAviso(String avisoId) =>
      _baseAvisos + (avisoId.hashCode & 0x3FFFFFFF);

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
  /// que a grade ou as disciplinas dele mudarem. Chamado depois do login (ou
  /// ao abrir o app já logado).
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
          (aulas) => unawaited(_reagendarAulas(aulas)),
          // Sem conexão, os lembretes já agendados continuam valendo.
          onError: (Object e) => debugPrint('Lembretes: $e'),
        );
  }

  /// Para de atualizar e apaga os lembretes agendados (ao sair da conta: o
  /// próximo a entrar no aparelho não deve receber os lembretes do anterior).
  static Future<void> parar() async {
    await _assinatura?.cancel();
    _assinatura = null;
    if (suportado && _pronto) await _plugin.cancelAll();
  }

  /// Agenda um aviso para cada um dos [avisos] da pessoa, no dia e horário
  /// marcados. Chamado sempre que a lista de avisos muda (criar ou excluir).
  /// Avisos cujo horário já passou não são agendados.
  static Future<void> sincronizarAvisos(List<Aviso> avisos) async {
    if (!suportado) return;

    try {
      await _inicializar();
      await _cancelarAvisos();

      final agora = DateTime.now();
      final modo = await _modoDeAgendamento();
      for (final aviso in avisos) {
        final quando = DateTime(
          aviso.data.year,
          aviso.data.month,
          aviso.data.day,
          aviso.hora.hour,
          aviso.hora.minute,
        );
        if (!quando.isAfter(agora)) continue;

        await _plugin.zonedSchedule(
          id: idDoAviso(aviso.id),
          scheduledDate: tz.TZDateTime(
            tz.local,
            quando.year,
            quando.month,
            quando.day,
            quando.hour,
            quando.minute,
          ),
          notificationDetails: const NotificationDetails(
            android: _detalhesAvisos,
          ),
          androidScheduleMode: modo,
          title: aviso.titulo,
          body: aviso.descricao.isEmpty
              ? 'Aviso da sua agenda'
              : aviso.descricao,
        );
      }
    } catch (e) {
      debugPrint('Avisos: $e');
    }
  }

  /// Exato, quando o Android permite (Android 14+ pode pedir uma permissão
  /// extra em Configurações); senão, o horário pode atrasar alguns minutos.
  static Future<AndroidScheduleMode> _modoDeAgendamento() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final podeExato = await android?.canScheduleExactNotifications() ?? false;
    return podeExato
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Cancela só as notificações de aulas, sem mexer nos avisos.
  static Future<void> _cancelarAulas() async {
    final pendentes = await _plugin.pendingNotificationRequests();
    for (final p in pendentes) {
      if (p.id < _baseAvisos) await _plugin.cancel(id: p.id);
    }
  }

  /// Cancela só as notificações de avisos, sem mexer nas aulas.
  static Future<void> _cancelarAvisos() async {
    final pendentes = await _plugin.pendingNotificationRequests();
    for (final p in pendentes) {
      if (p.id >= _baseAvisos) await _plugin.cancel(id: p.id);
    }
  }

  static Future<void> _reagendarAulas(List<Horario> aulas) async {
    await _cancelarAulas();

    const detalhes = NotificationDetails(android: _detalhesAulas);

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
