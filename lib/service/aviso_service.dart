import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/aviso.dart';
import 'auth_service.dart';

/// Erro de aviso já traduzido para mostrar na tela.
class ErroAviso implements Exception {
  final String mensagem;
  const ErroAviso(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Avisos/anotações pessoais da agenda (UC008).
abstract class AvisoService {
  static AvisoService instancia = FirebaseAvisoService();

  /// Avisos da pessoa logada, em ordem de dia e hora, sempre atualizados.
  Stream<List<Aviso>> meus();

  /// Salva o aviso em nome da pessoa logada. Lança [ErroAviso].
  Future<void> adicionar(Aviso aviso);

  /// Exclui o aviso. Lança [ErroAviso].
  Future<void> excluir(Aviso aviso);
}

class FirebaseAvisoService implements AvisoService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('avisos');

  @override
  Stream<List<Aviso>> meus() {
    final uid = AuthService.usuarioAtual?.uid;
    if (uid == null) return Stream.value(const []);

    return _colecao.where('autorId', isEqualTo: uid).snapshots().map((r) {
      final lista = [
        for (final doc in r.docs) ?Aviso.fromMap(doc.id, doc.data()),
      ];
      // Ordena aqui, e não na consulta, para não precisar de índice composto.
      lista.sort((a, b) {
        final porDia = a.data.compareTo(b.data);
        if (porDia != 0) return porDia;
        return (a.hora.hour * 60 + a.hora.minute).compareTo(
          b.hora.hour * 60 + b.hora.minute,
        );
      });
      return lista;
    });
  }

  @override
  Future<void> adicionar(Aviso aviso) async {
    final uid = AuthService.usuarioAtual?.uid;
    if (uid == null) throw const ErroAviso('Entre na sua conta para salvar.');

    try {
      await _colecao.add({
        ...Aviso(
          autorId: uid,
          titulo: aviso.titulo,
          descricao: aviso.descricao,
          data: aviso.data,
          hora: aviso.hora,
          cor: aviso.cor,
        ).toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroAviso(_traduzir(e.code));
    }
  }

  @override
  Future<void> excluir(Aviso aviso) async {
    try {
      await _colecao.doc(aviso.id).delete();
    } on FirebaseException catch (e) {
      throw ErroAviso(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) => switch (codigo) {
    'permission-denied' =>
      'Sem permissão para salvar. Verifique as regras do Firestore.',
    'unavailable' => 'Sem conexão. Verifique sua internet.',
    _ => 'Não foi possível salvar o aviso ($codigo).',
  };
}
