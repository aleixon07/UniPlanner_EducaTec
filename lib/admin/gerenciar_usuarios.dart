import 'package:flutter/material.dart';

import '../model/usuario.dart';
import '../service/usuario_service.dart';
import '../sidebar.dart';
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

/// Lista, busca e cadastra alunos ou professores, conforme o [perfil].
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

  @override
  void dispose() {
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
                          cinza: index.isOdd,
                          onEditar: () => _avisar(
                            'A edição de ${widget.perfil.rotuloPlural.toLowerCase()} '
                            'ainda não está disponível.',
                          ),
                          onDesativar: () => _avisar(
                            'A desativação de ${widget.perfil.rotuloPlural.toLowerCase()} '
                            'ainda não está disponível.',
                          ),
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
  final bool cinza;
  final VoidCallback onEditar;
  final VoidCallback onDesativar;

  const _CardUsuario({
    required this.usuario,
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
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  usuario.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // TODO: ligar ao fluxo de edição quando ele existir.
          IconButton(
            onPressed: onEditar,
            tooltip: 'Editar',
            icon: const Icon(Icons.edit, color: _azul, size: 20),
          ),

          // TODO: ligar à desativação. Desativar também precisa bloquear o
          // login dessa conta, o que ainda não existe.
          IconButton(
            onPressed: onDesativar,
            tooltip: 'Desativar',
            icon: const Icon(
              Icons.indeterminate_check_box_outlined,
              color: _vermelho,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
