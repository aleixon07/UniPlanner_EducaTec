import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sala.dart';

/// Erro de cadastro de sala já traduzido para mostrar na tela.
class ErroSala implements Exception {
  final String mensagem;
  const ErroSala(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso às salas e laboratórios.
///
/// Segue o mesmo modelo do [UsuarioService]: classe abstrata, para as telas
/// poderem ser testadas sem Firebase trocando [instancia] por uma versão falsa.
abstract class SalaService {
  static SalaService instancia = FirebaseSalaService();

  /// Ambientes que já existiam no protótipo. O administrador pode cadastrá-los
  /// de uma vez pela tela de gerenciamento, quando a lista estiver vazia.
  static const List<Sala> salasPadrao = [
    Sala(numero: '301', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '302', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '303', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '304', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '305', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '306', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '307', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '308', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '309', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '310', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '311', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '312', tipo: TipoSala.sala, andar: '3º Andar'),
    Sala(numero: '402', tipo: TipoSala.laboratorio, andar: '4º Andar'),
    Sala(numero: '408', tipo: TipoSala.laboratorio, andar: '4º Andar'),
    Sala(numero: '409', tipo: TipoSala.laboratorio, andar: '4º Andar'),
  ];

  /// Todos os ambientes, ordenados com [compararSalas], sempre atualizados.
  Stream<List<Sala>> listar();

  /// Cadastra um ambiente. Lança [ErroSala] se já existir ou se der erro.
  Future<void> cadastrar({
    required String numero,
    required TipoSala tipo,
    required String andar,
  });

  /// Remove um ambiente. Lança [ErroSala].
  Future<void> remover(Sala sala);

  /// Cadastra os [salasPadrao]. Lança [ErroSala].
  Future<void> cadastrarPadrao();
}

class FirebaseSalaService implements SalaService {
  // Só toca no Firebase quando é usado, para criar o objeto não exigir
  // Firebase.initializeApp().
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('salas');

  @override
  Stream<List<Sala>> listar() {
    return _colecao.snapshots().map((resultado) {
      final lista = resultado.docs
          .map((doc) => Sala.fromMap(doc.id, doc.data()))
          .toList();
      lista.sort(compararSalas);
      return lista;
    });
  }

  @override
  Future<void> cadastrar({
    required String numero,
    required TipoSala tipo,
    required String andar,
  }) async {
    final numeroLimpo = numero.trim().toUpperCase();
    final documento = _colecao.doc(Sala.idPara(numeroLimpo, tipo));

    try {
      final existente = await documento.get();
      if (existente.exists) {
        final nome = tipo == TipoSala.laboratorio
            ? 'um laboratório'
            : 'uma sala';
        throw ErroSala('Já existe $nome com o número $numeroLimpo.');
      }

      await documento.set({
        ...Sala(numero: numeroLimpo, tipo: tipo, andar: andar.trim()).toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ErroSala(_traduzir(e.code));
    }
  }

  @override
  Future<void> remover(Sala sala) async {
    try {
      await _colecao.doc(sala.id).delete();
    } on FirebaseException catch (e) {
      throw ErroSala(_traduzir(e.code));
    }
  }

  @override
  Future<void> cadastrarPadrao() async {
    final lote = FirebaseFirestore.instance.batch();

    for (final sala in SalaService.salasPadrao) {
      lote.set(_colecao.doc(Sala.idPara(sala.numero, sala.tipo)), {
        ...sala.toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }

    try {
      await lote.commit();
    } on FirebaseException catch (e) {
      throw ErroSala(_traduzir(e.code));
    }
  }

  String _traduzir(String codigo) {
    switch (codigo) {
      case 'permission-denied':
        return 'Sem permissão para salvar. Verifique as regras do Firestore.';
      case 'unavailable':
        return 'Sem conexão. Verifique sua internet.';
      default:
        return 'Não foi possível salvar a sala ($codigo).';
    }
  }
}
