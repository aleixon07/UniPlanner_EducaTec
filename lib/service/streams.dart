import 'dart:async';

/// Para cada valor de [fonte], passa a ouvir o stream que [criar] devolve,
/// largando o anterior (o "switchMap" de outras bibliotecas).
///
/// Exemplo: a lista de disciplinas de um professor muda -> troca a consulta
/// dos horários dessas disciplinas. Sem largar a consulta antiga, ficariam
/// duas conexões abertas misturando resultados.
Stream<T> trocarPara<S, T>(Stream<S> fonte, Stream<T> Function(S) criar) {
  late StreamController<T> saida;
  StreamSubscription<S>? assinaturaFonte;
  StreamSubscription<T>? assinaturaAtual;

  saida = StreamController<T>(
    onListen: () {
      assinaturaFonte = fonte.listen(
        (valor) {
          assinaturaAtual?.cancel();
          assinaturaAtual = criar(valor)
              .listen(saida.add, onError: saida.addError);
        },
        onError: saida.addError,
        onDone: () {},
      );
    },
    onCancel: () async {
      await assinaturaAtual?.cancel();
      await assinaturaFonte?.cancel();
    },
  );
  return saida.stream;
}
