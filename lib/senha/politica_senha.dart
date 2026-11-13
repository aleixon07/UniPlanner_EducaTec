// Regras de senha do UniPlanner, num lugar só.

/// Senha temporária de quem acabou de ser cadastrado: o primeiro nome em
/// minúsculas e sem acentos, mais "123". Ex.: "Alexandre Souza" -> `alexandre123`.
///
/// O Firebase exige pelo menos 6 caracteres. Para nomes curtos ("Li" daria
/// `li123`, com 5), os números continuam até chegar a 6: `li1234`.
String senhaTemporariaPara(String nome) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';

  final primeiro = nome.trim().split(RegExp(r'\s+')).first.toLowerCase();
  final saida = StringBuffer();
  for (final letra in primeiro.split('')) {
    final i = comAcento.indexOf(letra);
    final normal = i == -1 ? letra : semAcento[i];
    // Só letras e números: um nome como "D'Ávila" vira "davila".
    if (RegExp(r'[a-z0-9]').hasMatch(normal)) saida.write(normal);
  }

  var senha = '${saida}123';
  var proximo = 4;
  while (senha.length < 6) {
    senha += '${proximo % 10}';
    proximo++;
  }
  return senha;
}

/// Valida a senha nova que a pessoa escolhe no primeiro login. Devolve a
/// mensagem de erro, ou `null` se a senha for aceita.
String? validarSenha(String senha) {
  // Política: pelo menos 6 caracteres (o mínimo do Firebase), com pelo menos
  // uma letra e um número. Uma mensagem por vez, da regra mais básica para a
  // mais específica.
  if (senha.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
  if (!RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(senha)) {
    return 'A senha precisa ter pelo menos uma letra.';
  }
  if (!RegExp(r'[0-9]').hasMatch(senha)) {
    return 'A senha precisa ter pelo menos um número.';
  }
  return null;
}
