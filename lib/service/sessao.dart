import 'package:flutter/foundation.dart';

import '../model/usuario.dart';

/// Quem está logado agora, com o perfil (RF002).
///
/// É preenchida pelo `AuthService` no login e limpa ao sair. As telas leem
/// daqui para decidir o que mostrar (por exemplo, o menu Admin só aparece para
/// administradores). Como é um [ValueNotifier], quem precisar pode ouvir
/// mudanças (o nome trocado, a senha temporária resolvida...).
class Sessao {
  Sessao._();

  static final ValueNotifier<Usuario?> atual = ValueNotifier(null);

  static Usuario? get usuario => atual.value;

  static bool get ehAdmin => usuario?.perfil == PerfilUsuario.administrador;
  static bool get ehProfessor => usuario?.perfil == PerfilUsuario.professor;
  static bool get ehAluno => usuario?.perfil == PerfilUsuario.aluno;
}
