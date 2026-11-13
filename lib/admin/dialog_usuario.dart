import 'package:flutter/material.dart';

import '../model/usuario.dart';
import '../service/usuario_service.dart';
import '../senha/politica_senha.dart';
import 'select_curso.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

String? _validarNome(String nome) {
  return nome.trim().isEmpty ? 'Informe o nome.' : null;
}

String? _validarEmail(String email) {
  final valor = email.trim();
  if (valor.isEmpty) return 'Informe o e-mail.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor)) {
    return 'E-mail inválido.';
  }
  return null;
}

/// Modal para cadastrar um aluno, professor ou administrador: nome e e-mail
/// (e o curso, para aluno). A senha é temporária, gerada a partir do nome.
///
/// Faz o cadastro de verdade ao confirmar (cria a conta e salva no banco) e só
/// fecha se der certo, devolvendo o nome cadastrado. Se der erro, mostra a
/// mensagem aqui mesmo e mantém os dados digitados.
class DialogUsuario extends StatefulWidget {
  final PerfilUsuario perfil;

  const DialogUsuario({super.key, required this.perfil});

  @override
  State<DialogUsuario> createState() => _DialogUsuarioState();
}

class _DialogUsuarioState extends State<DialogUsuario> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();

  String? _erroNome;
  String? _erroEmail;
  String? _erroGeral;

  String? _cursoId;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = senhaTemporariaPara(nome);

    setState(() {
      _erroNome = _validarNome(nome);
      _erroEmail = _validarEmail(email);
      _erroGeral = null;
    });

    if (_erroNome != null || _erroEmail != null) return;

    setState(() => _salvando = true);

    try {
      await UsuarioService.instancia.cadastrar(
        nome: nome,
        email: email,
        senha: senha,
        perfil: widget.perfil,
        cursoId: _cursoId,
      );
      if (!mounted) return;
      Navigator.pop(context, nome);
    } on ErroCadastro catch (e) {
      if (!mounted) return;
      setState(() {
        _erroGeral = e.mensagem;
        _salvando = false;
      });
    } catch (_) {
      // Qualquer imprevisto: sem isto o botão ficaria travado em "salvando".
      if (!mounted) return;
      setState(() {
        _erroGeral = 'Erro inesperado ao cadastrar. Tente novamente.';
        _salvando = false;
      });
    }
  }

  InputDecoration _decoracao(String dica, {String? erro, Widget? sufixo}) {
    return InputDecoration(
      hintText: dica,
      errorText: erro,
      suffixIcon: sufixo,
      hintStyle: const TextStyle(
        fontFamily: 'NunitoSans',
        color: Color(0xFF9E9E9E),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto salva, não deixa fechar: o cadastro continuaria rodando sem
    // ninguém para mostrar o resultado.
    return PopScope(
      canPop: !_salvando,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adicionar ${widget.perfil.rotulo}',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _nomeController,
                enabled: !_salvando,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: _decoracao('Nome', erro: _erroNome),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                enabled: !_salvando,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _cadastrar(),
                style: const TextStyle(fontFamily: 'NunitoSans'),
                decoration: _decoracao('E-mail', erro: _erroEmail),
              ),

              const SizedBox(height: 12),

              // SENHA TEMPORÁRIA: gerada a partir do nome. A pessoa é obrigada
              // a trocá-la no primeiro login.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Senha temporária',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 12,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      _nomeController.text.trim().isEmpty
                          ? 'Preencha o nome'
                          : senhaTemporariaPara(_nomeController.text),
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _azulEscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Passe para a pessoa. No primeiro acesso ela terá que '
                      'criar uma senha nova.',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 12,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.perfil == PerfilUsuario.aluno) ...[
                const SizedBox(height: 12),
                SelectCurso(
                  valor: _cursoId,
                  habilitado: !_salvando,
                  onChanged: (valor) => setState(() => _cursoId = valor),
                ),
              ],

              if (_erroGeral != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erroGeral!,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _vermelho,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _salvando
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE3E3E3),
                        foregroundColor: const Color(0xFF4A4A4A),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _cadastrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Cadastrar',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'NunitoSans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
