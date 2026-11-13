import 'package:flutter/material.dart';

import '../model/reserva.dart';
import '../model/usuario.dart';
import '../service/formatador_data.dart';
import '../service/reserva_service.dart';
import '../service/usuario_service.dart';
import '../sidebar.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _vermelho = Color(0xFFE23B3B);

/// Tira acentos e maiúsculas, para a busca achar "Lab." digitando "lab".
String _paraBusca(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final saida = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    final i = de.indexOf(letra);
    saida.write(i == -1 ? letra : para[i]);
  }
  return saida.toString();
}

/// Todas as reservas de todos os usuários, de hoje em diante (UC006). O
/// administrador busca e cancela qualquer uma.
class GerenciarReservas extends StatefulWidget {
  const GerenciarReservas({super.key});

  @override
  State<GerenciarReservas> createState() => _GerenciarReservasState();
}

class _GerenciarReservasState extends State<GerenciarReservas> {
  late final Stream<List<Reserva>> _reservas = ReservaService.instancia.todas();
  late final Stream<List<Usuario>> _usuarios = UsuarioService.instancia.todos();
  final TextEditingController _buscaController = TextEditingController();
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

  Future<void> _cancelar(Reserva reserva, String quem) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cancelar reserva?',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontWeight: FontWeight.w800,
            color: _azulEscuro,
          ),
        ),
        content: Text(
          '${reserva.sala.rotuloCurto} ${reserva.sala.numero} • '
          '${formatarData(reserva.data)} • ${reserva.turno.rotulo}\n'
          '"${reserva.disciplina}", reservada por $quem.',
          style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    try {
      await ReservaService.instancia.cancelar(reserva);
      if (mounted) _avisar('Reserva cancelada.');
    } on ErroReserva catch (e) {
      if (mounted) _avisar(e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Column(
                  children: [
                    const Text(
                      'Reservas',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _azulEscuro,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _buscaController,
                      onChanged: (v) => setState(() => _busca = v),
                      style: const TextStyle(fontFamily: 'NunitoSans'),
                      decoration: InputDecoration(
                        hintText: 'Buscar por sala, disciplina ou pessoa',
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
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Usuario>>(
                  stream: _usuarios,
                  builder: (context, snapUsuarios) {
                    return StreamBuilder<List<Reserva>>(
                      stream: _reservas,
                      builder: (context, snapReservas) {
                        if (snapReservas.hasError) {
                          return const _Mensagem(
                            'Não foi possível carregar as reservas.',
                            cor: _vermelho,
                          );
                        }
                        final reservas = snapReservas.data;
                        if (reservas == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final nomes = {
                          for (final u
                              in snapUsuarios.data ?? const <Usuario>[])
                            u.id: u.nome,
                        };
                        String quem(Reserva r) =>
                            nomes[r.usuarioId] ?? 'usuário não encontrado';

                        final termo = _paraBusca(_busca.trim());
                        final visiveis = termo.isEmpty
                            ? reservas
                            : reservas.where((r) {
                                final texto = _paraBusca(
                                  '${r.sala.rotuloCurto} ${r.sala.numero} '
                                  '${r.disciplina} ${quem(r)}',
                                );
                                return texto.contains(termo);
                              }).toList();

                        if (reservas.isEmpty) {
                          return const _Mensagem(
                            'Nenhuma reserva de hoje em diante.',
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
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final r = visiveis[i];
                            final novoDia =
                                i == 0 || !visiveis[i - 1].ehDoDia(r.data);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (novoDia)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 6,
                                    ),
                                    child: Text(
                                      formatarData(r.data),
                                      style: const TextStyle(
                                        fontFamily: 'NunitoSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _azulEscuro,
                                      ),
                                    ),
                                  ),
                                _CardReserva(
                                  reserva: r,
                                  quem: quem(r),
                                  onCancelar: () => _cancelar(r, quem(r)),
                                ),
                              ],
                            );
                          },
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

class _CardReserva extends StatelessWidget {
  final Reserva reserva;
  final String quem;
  final VoidCallback onCancelar;

  const _CardReserva({
    required this.reserva,
    required this.quem,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Text(
                  reserva.sala.rotuloCurto,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  reserva.sala.numero,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _azulEscuro,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reserva.disciplina,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _azulEscuro,
                  ),
                ),
                Text(
                  '${reserva.turno.rotulo} • $quem',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancelar,
            tooltip: 'Cancelar reserva',
            icon: const Icon(Icons.close, color: _vermelho, size: 20),
          ),
        ],
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
