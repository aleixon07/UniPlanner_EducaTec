import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/horario.dart';
import '../model/reserva.dart';
import '../model/sala.dart';
import 'auth_service.dart';
import 'horario_service.dart';

/// Erro de reserva já traduzido para mostrar na tela.
class ErroReserva implements Exception {
  final String mensagem;
  const ErroReserva(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso às reservas de salas.
///
/// Mesmo modelo do `UsuarioService` e do `SalaService`: classe abstrata, para
/// as telas poderem ser testadas sem Firebase trocando [instancia].
abstract class ReservaService {
  static ReservaService instancia = FirebaseReservaService();

  /// Reservas do usuário logado, de hoje em diante, em ordem de data e turno.
  Stream<List<Reserva>> minhasReservas();

  /// Todas as reservas de uma sala (de qualquer usuário). Usado pelo
  /// calendário para pintar os dias ocupados.
  Stream<List<Reserva>> reservasDaSala(Sala sala);

  /// Todas as reservas de todos os usuários, de hoje em diante, em ordem de
  /// data e turno. Usado pelo administrador (UC006).
  Stream<List<Reserva>> todas();

  /// Reservas (de qualquer pessoa) das disciplinas, de hoje em diante. Assim o
  /// aluno vê em "Aulas do Dia" a aula extra ou a troca de sala que o
  /// professor reservou.
  Stream<List<Reserva>> dasDisciplinas(List<String> disciplinaIds);

  /// Salva a reserva em nome do usuário logado. Lança [ErroReserva] se a sala
  /// já estiver ocupada nesse dia e turno, ou se der erro.
  Future<void> reservar(Reserva reserva);

  /// Cancela (apaga) a reserva. Lança [ErroReserva].
  Future<void> cancelar(Reserva reserva);
}

class FirebaseReservaService implements ReservaService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('reservas');

  List<Reserva> _converter(QuerySnapshot<Map<String, dynamic>> resultado) {
    return [
      for (final doc in resultado.docs) ?Reserva.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Stream<List<Reserva>> minhasReservas() {
    final uid = AuthService.usuarioAtual?.uid;
    if (uid == null) return Stream.value(const []);

    return _colecao
        .where('usuarioId', isEqualTo: uid)
        .snapshots()
        .map(_deHojeEmDiante);
  }

  /// Filtra e ordena aqui, e não na consulta, para não precisar criar índice
  /// composto no Firestore.
  List<Reserva> _deHojeEmDiante(QuerySnapshot<Map<String, dynamic>> r) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final lista = _converter(r).where((r) => !r.data.isBefore(hoje)).toList();
    lista.sort((a, b) {
      final porData = a.data.compareTo(b.data);
      return porData != 0 ? porData : a.turno.index.compareTo(b.turno.index);
    });
    return lista;
  }

  @override
  Stream<List<Reserva>> todas() => _colecao.snapshots().map(_deHojeEmDiante);

  @override
  Stream<List<Reserva>> dasDisciplinas(List<String> disciplinaIds) {
    if (disciplinaIds.isEmpty) return Stream.value(const []);
    // whereIn aceita até 30 valores (veja HorarioService.dasDisciplinas).
    return _colecao
        .where('disciplinaId', whereIn: disciplinaIds.take(30).toList())
        .snapshots()
        .map(_deHojeEmDiante);
  }

  @override
  Stream<List<Reserva>> reservasDaSala(Sala sala) {
    return _colecao
        .where('salaId', isEqualTo: Reserva.salaIdDe(sala))
        .snapshots()
        .map(_converter);
  }

  @override
  Future<void> reservar(Reserva reserva) async {
    final uid = AuthService.usuarioAtual?.uid;
    if (uid == null) {
      throw const ErroReserva('Entre na sua conta para reservar.');
    }

    // A grade de horários tem prioridade: a sala com aula fixa nesse dia da
    // semana e turno não pode ser reservada (a reserva é a exceção, não a
    // regra).
    final dia = DiaSemanaInfo.de(reserva.data);
    if (dia != null) {
      final Horario? fixa;
      try {
        fixa = await HorarioService.instancia.ocupando(
          reserva.sala,
          dia,
          reserva.turno,
        );
      } on FirebaseException catch (e) {
        throw ErroReserva(_traduzir(e.code));
      }
      if (fixa != null) {
        throw ErroReserva(
          'Esta sala tem aula fixa de "${fixa.disciplinaNome}" nesse dia e '
          'turno. Escolha outro dia, turno ou sala.',
        );
      }
    }

    final documento = _colecao.doc(
      Reserva.idPara(reserva.sala, reserva.turno, reserva.data),
    );

    final bool criada;
    try {
      // Transação: ler e gravar juntos. Se duas pessoas reservarem a mesma
      // sala ao mesmo tempo, só uma consegue.
      criada = await FirebaseFirestore.instance.runTransaction<bool>((
        transacao,
      ) async {
        final existente = await transacao.get(documento);
        if (existente.exists) return false;

        transacao.set(documento, {
          ...reserva.toMap(),
          'usuarioId': uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } on FirebaseException catch (e) {
      throw ErroReserva(_traduzir(e.code));
    }

    if (!criada) {
      throw const ErroReserva(
        'Esta sala acabou de ser reservada nesse dia e turno. '
        'Escolha outro dia ou turno.',
      );
    }
  }

  @override
  Future<void> cancelar(Reserva reserva) async {
    try {
      await _colecao.doc(reserva.id).delete();
    } on FirebaseException catch (e) {
      throw ErroReserva(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) {
    switch (codigo) {
      case 'permission-denied':
        return 'Sem permissão. Verifique as regras do Firestore.';
      case 'unavailable':
        return 'Sem conexão. Verifique sua internet.';
      default:
        return 'Não foi possível concluir a operação ($codigo).';
    }
  }
}
