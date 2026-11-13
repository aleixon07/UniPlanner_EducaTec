import 'dart:async';

import 'package:flutter/material.dart';

import '../model/curso.dart';
import '../model/usuario.dart';
import '../service/curso_service.dart';
import '../service/sessao.dart';
import '../service/usuario_service.dart';
import '../sidebar.dart';
import 'dialog_editar_usuario.dart';
import 'dialog_usuario.dart';

const Color _azul = Color(0xFF3750B5);
const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);

/// Tira acentos e maiúsculas, para a busca achar "João" digitando "joao".
String _paraBusca(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final minusculo = texto.toLowerCase();
  final saida = StringBuffer();
  for (final letra in minusculo.split('')) {
    final i = de.indexOf(letra);
    saida.write(i == -1 ? letra : para[i]);
  }
  return saida.toString();
}

/// Lista, busca e cadastra alunos, professores ou administradores, conforme o
/// [perfil].
/// Os dados vêm do Firestore e a lista se atualiza sozinha.
class GerenciarUsuarios extends StatefulWidget {
  final PerfilUsuario perfil;

  const GerenciarUsuarios({super.key, required this.perfil});

  @override
  State<GerenciarUsuarios> createState() => _GerenciarUsuariosState();
}

class _GerenciarUsuariosState extends State<GerenciarUsuarios> {
  final TextEditingController _buscaController = TextEditingController();

  // Criado uma vez só: se fosse criado no build, cada letra digitada na busca
  // abriria uma nova conexão com o Firestore.
  late final Stream<List<Usuario>> _usuarios = UsuarioService.instancia.listar(
    widget.perfil,
  );

  String _busca = '';

  // id do curso -> nome, para mostrar o curso de cada aluno. Só alunos têm curso.
  Map<String, String> _nomesCursos = {};
  StreamSubscription<List<Curso>>? _assinaturaCursos;

  @override
  void initState() {
    super.initState();
    if (widget.perfil == PerfilUsuario.aluno) {
      _assinaturaCursos = CursoService.instancia.listar().listen((cursos) {
        if (!mounted) return;
        setState(() => _nomesCursos = {for (final c in cursos) c.id: c.nome});
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _assinaturaCursos?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: const TextStyle(fontFamily: 'NunitoSans'),
          ),
        ),
      );
  }

  Future<void> _adicionar() async {
    final nome = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogUsuario(perfil: widget.perfil),
    );

    if (nome == null || !mounted) return;
    _avisar('${widget.perfil.rotulo} "$nome" cadastrado.');
  }

  // O modal já salva no banco, e a lista se atualiza sozinha pelo stream.
  Future<void> _editar(Usuario usuario) async {
    final nome = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogEditarUsuario(usuario: usuario),
    );

    if (nome == null || !mounted) return;
    _avisar('${widget.perfil.rotulo} atualizado.');
  }

  Future<void> _alternarAtivo(Usuario usuario) async {
    // Desativar a si mesmo trancaria a pessoa fora do app (e, se for o único
    // administrador, ninguém mais entraria na área administrativa).
    if (usuario.ativo && usuario.id == Sessao.usuario?.id) {
      _avisar('Você não pode desativar a sua própria conta.');
      return;
    }

    if (usuario.ativo) {
      final confirmou = await confirmarDesativacaoUsuario(context, usuario);
      if (!confirmou || !mounted) return;
    }

    try {
      await UsuarioService.instancia.definirAtivo(usuario.id, !usuario.ativo);
      if (!mounted) return;
      _avisar(
        usuario.ativo
            ? '"${usuario.nome}" desativado.'
            : '"${usuario.nome}" reativado.',
      );
    } on ErroCadastro catch (e) {
      if (!mounted) return;
      _avisar(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotulo = widget.perfil.rotulo;

    return Scaffold(
      appBar: const AppBarUniPlanner(admin: true),
      drawer: const Sidebar(),
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  children: [
                    Text(
                      'Gerenciamento de ${widget.perfil.rotuloPlural}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _azulEscuro,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // BUSCA
                    TextField(
                      controller: _buscaController,
                      onChanged: (valor) => setState(() => _busca = valor),
                      style: const TextStyle(fontFamily: 'NunitoSans'),
                      decoration: InputDecoration(
                        hintText: 'Digite o nome do ${rotulo.toLowerCase()}',
                        hintStyle: const TextStyle(
                          fontFamily: 'NunitoSans',
                          color: Color(0xFF6B6F85),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE3E8F8),
                        suffixIcon: const Icon(
                          Icons.search,
                          color: _azulEscuro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ADICIONAR
                    InkWell(
                      onTap: _adicionar,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Adicionar $rotulo',
                              style: const TextStyle(
                                fontFamily: 'NunitoSans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _azul,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE3E8F8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: _azul,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<Usuario>>(
                  stream: _usuarios,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _Mensagem(
                        'Não foi possível carregar a lista. '
                        'Verifique a conexão e as regras do Firestore.',
                        cor: _vermelho,
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final todos = snapshot.data!;
                    final termo = _paraBusca(_busca.trim());
                    final visiveis = termo.isEmpty
                        ? todos
                        : todos
                              .where((u) => _paraBusca(u.nome).contains(termo))
                              .toList();

                    if (todos.isEmpty) {
                      return _Mensagem(
                        'Nenhum ${rotulo.toLowerCase()} cadastrado.',
                      );
                    }

                    if (visiveis.isEmpty) {
                      return _Mensagem(
                        'Nenhum resultado para "${_busca.trim()}".',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: visiveis.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _CardUsuario(
                          usuario: visiveis[index],
                          curso: _nomesCursos[visiveis[index].cursoId],
                          cinza: index.isOdd,
                          onEditar: () => _editar(visiveis[index]),
                          onDesativar: () => _alternarAtivo(visiveis[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Mensagem(this.texto, {this.cor = const Color(0xFF7A7A7A)});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: cor),
        ),
      ),
    );
  }
}

// ================================================================
// USUÁRIO NA LISTA (linhas alternam entre branco e cinza)
// ================================================================
class _CardUsuario extends StatelessWidget {
  final Usuario usuario;
  final String? curso;
  final bool cinza;
  final VoidCallback onEditar;
  final VoidCallback onDesativar;

  const _CardUsuario({
    required this.usuario,
    this.curso,
    required this.cinza,
    required this.onEditar,
    required this.onDesativar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: cinza ? const Color(0xFFEDEDED) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cinza ? Colors.transparent : const Color(0xFFD6D6D6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nome,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: usuario.ativo ? Colors.black87 : Colors.black45,
                  ),
                ),
                Text(
                  usuario.ativo ? usuario.email : '${usuario.email} • Inativo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    fontWeight: usuario.ativo ? null : FontWeight.w700,
                    color: usuario.ativo ? Colors.black54 : _vermelho,
                  ),
                ),
                if (curso != null)
                  Text(
                    curso!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _azulEscuro,
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            onPressed: onEditar,
            tooltip: 'Editar',
            icon: const Icon(Icons.edit, color: _azul, size: 20),
          ),

          // Desativa; se o usuário já está inativo, o mesmo lugar reativa.
          IconButton(
            onPressed: onDesativar,
            tooltip: usuario.ativo ? 'Desativar' : 'Reativar',
            icon: Icon(
              usuario.ativo
                  ? Icons.indeterminate_check_box_outlined
                  : Icons.restore,
              color: usuario.ativo ? _vermelho : const Color(0xFF27AE60),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
