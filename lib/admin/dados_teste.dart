import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/aviso.dart';
import '../model/curso.dart';
import '../model/disciplina.dart';
import '../model/horario.dart';
import '../model/matricula.dart';
import '../model/reserva.dart';
import '../model/semestre.dart';
import '../model/usuario.dart';
import '../senha/politica_senha.dart';
import '../service/auth_service.dart';
import '../service/disciplina_service.dart';
import '../service/sala_service.dart';
import '../service/usuario_service.dart';
import '../sidebar.dart';

const Color _azulEscuro = Color(0xFF203F7D);
const Color _verde = Color(0xFF27AE60);
const Color _vermelho = Color(0xFFE23B3B);

// ================================================================
// O QUE É GERADO
// ================================================================

/// Curso de teste: o nome, o turno das aulas e as disciplinas de cada um dos
/// 4 semestres.
const _cursos = <(String, Turno, List<List<String>>)>[
  (
    'Sistemas de Informação',
    Turno.manha,
    [
      [
        'Algoritmos',
        'Matemática Discreta',
        'Introdução à Computação',
        'Inglês Técnico',
      ],
      [
        'Programação I',
        'Banco de Dados I',
        'Cálculo I',
        'Arquitetura de Computadores',
      ],
      [
        'Programação II',
        'Banco de Dados II',
        'Estrutura de Dados',
        'Engenharia de Software',
      ],
      [
        'Redes de Computadores',
        'Interface Humano Computador',
        'Sistemas Operacionais',
        'Projeto Integrador',
      ],
    ],
  ),
  (
    'Gestão de Turismo',
    Turno.tarde,
    [
      [
        'Fundamentos do Turismo',
        'Geografia do Turismo',
        'Comunicação',
        'Espanhol I',
      ],
      ['Planejamento Turístico', 'Hospitalidade', 'Marketing', 'Espanhol II'],
      [
        'Gestão de Eventos',
        'Turismo Rural',
        'Empreendedorismo',
        'Legislação do Turismo',
      ],
      [
        'Agenciamento',
        'Patrimônio Cultural',
        'Gestão Financeira',
        'Estágio Supervisionado',
      ],
    ],
  ),
  (
    'Licenciatura em Matemática',
    Turno.noite,
    [
      [
        'Fundamentos de Matemática',
        'Geometria Plana',
        'Leitura e Produção Textual',
        'História da Educação',
      ],
      [
        'Cálculo Diferencial',
        'Geometria Analítica',
        'Didática',
        'Psicologia da Educação',
      ],
      [
        'Cálculo Integral',
        'Álgebra Linear',
        'Física Geral',
        'Metodologia do Ensino',
      ],
      ['Estatística', 'Equações Diferenciais', 'Libras', 'Prática de Ensino'],
    ],
  ),
];

const _professores = [
  'Ana Souza',
  'Bruno Lima',
  'Carla Mendes',
  'Diego Rocha',
  'Elaine Farias',
  'Fábio Antunes',
];

const _alunos = [
  'Gabriel Martins',
  'Helena Costa',
  'Igor Pereira',
  'Júlia Ramos',
  'Kauan Oliveira',
  'Larissa Silva',
  'Mateus Barbosa',
  'Natália Gomes',
  'Otávio Ribeiro',
  'Paula Cardoso',
  'Rafael Teixeira',
  'Sabrina Alves',
  'Thiago Nunes',
  'Úrsula Castro',
  'Vinícius Moraes',
  'Wesley Duarte',
  'Yasmin Freitas',
  'Arthur Vieira',
  'Bianca Lopes',
  'Caio Machado',
];

const _avisos = [
  ('Reunião de colegiado', 'Sala dos professores'),
  ('Entrega de notas', 'Lançar no sistema acadêmico'),
  ('Conselho de classe', 'Turmas do 1º semestre'),
  ('Palestra', 'Uso de IA na educação'),
  ('Prova', 'Conteúdo das unidades 1 e 2'),
  ('Semana acadêmica', 'Abertura no auditório'),
  ('Relatório', 'Entregar relatório das bolsas'),
  ('Visita técnica', 'Saída às 8h em frente ao campus'),
];

/// E-mail de teste de uma pessoa: `ana.souza@example.com`. O domínio
/// example.com é reservado para testes: nunca chega em ninguém de verdade.
String emailDeTeste(String nome) {
  const com = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const sem = 'aaaaaeeeeiiiiooooouuuucn';
  final saida = StringBuffer();
  for (final letra in nome.trim().toLowerCase().split('')) {
    final i = com.indexOf(letra);
    saida.write(i == -1 ? letra : sem[i]);
  }
  return '${saida.toString().replaceAll(RegExp(r'\s+'), '.')}@example.com';
}

// ================================================================
// GERADOR
// ================================================================

/// Gera e remove os dados de teste. Tudo o que ele cria leva o campo
/// `teste: true`, e é só isso que a remoção apaga: os dados reais ficam.
///
/// Roda no app, com a conta do administrador logado; por isso obedece às
/// regras do Firestore como qualquer outra tela.
class DadosTeste {
  DadosTeste(this.registrar);

  /// Recebe cada linha de progresso, para a tela mostrar.
  final void Function(String linha) registrar;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<bool> _jaExistem() async {
    final r = await _db
        .collection('cursos')
        .where('teste', isEqualTo: true)
        .limit(1)
        .get();
    return r.docs.isNotEmpty;
  }

  Future<void> gerar() async {
    final admin = AuthService.usuarioAtual?.uid;
    if (admin == null) throw StateError('Entre como administrador.');
    if (await _jaExistem()) {
      registrar('Já existem dados de teste. Remova antes de gerar de novo.');
      return;
    }

    // ---------------- SALAS ----------------
    var salas = await SalaService.instancia.listar().first;
    if (salas.isEmpty) {
      await SalaService.instancia.cadastrarPadrao();
      salas = await SalaService.instancia.listar().first;
      registrar('Salas padrão cadastradas (${salas.length}).');
    }
    // As 12 primeiras ficam com a grade; as demais, com as reservas.
    final salasGrade = salas.take(12).toList();
    final salasLivres = salas.skip(12).toList();
    if (salasGrade.length < 4) {
      registrar('São necessárias pelo menos 4 salas. Cadastre mais salas.');
      return;
    }

    // ---------------- PESSOAS ----------------
    final professores = await _pessoas(_professores, PerfilUsuario.professor);
    registrar('Professores prontos: ${professores.length}.');

    // ---------------- CURSOS, SEMESTRES, DISCIPLINAS, GRADE ----------------
    // Guarda as disciplinas de cada (curso, semestre) para as matrículas.
    final turmas = <(String cursoId, List<Disciplina> disciplinas)>[];
    final todasDisciplinas = <Disciplina>[];

    for (var c = 0; c < _cursos.length; c++) {
      final (nomeCurso, turno, semestres) = _cursos[c];
      final lote = _db.batch();

      final cursoRef = _db.collection('cursos').doc();
      lote.set(cursoRef, {
        ...Curso(id: cursoRef.id, nome: nomeCurso).toMap(),
        'teste': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      for (var s = 0; s < semestres.length; s++) {
        final semestreRef = _db.collection('semestres').doc();
        lote.set(semestreRef, {
          ...Semestre(
            id: semestreRef.id,
            cursoId: cursoRef.id,
            numero: s + 1,
          ).toMap(),
          'teste': true,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        // Cada turma tem a sua sala: cursos em turnos diferentes e turmas em
        // salas diferentes, então a grade nasce sem conflito.
        final sala = salasGrade[(c * 4 + s) % salasGrade.length];
        final daTurma = <Disciplina>[];

        for (var d = 0; d < semestres[s].length; d++) {
          final disciplinaRef = _db.collection('disciplinas').doc();
          final professor = professores.isEmpty
              ? null
              : professores[(c * 2 + s + d) % professores.length];
          final disciplina = Disciplina(
            id: disciplinaRef.id,
            cursoId: cursoRef.id,
            semestreId: semestreRef.id,
            nome: semestres[s][d],
            professorIds: [?professor?.id],
          );
          daTurma.add(disciplina);
          lote.set(disciplinaRef, {
            ...disciplina.toMap(),
            'teste': true,
            'criadoEm': FieldValue.serverTimestamp(),
          });

          // Uma aula por semana: 1ª disciplina na segunda, 2ª na terça...
          final dia = DiaSemana.values[d % DiaSemana.values.length];
          lote.set(
            _db
                .collection('horarios')
                .doc(Horario.idPara(semestreRef.id, dia, turno)),
            {
              ...Horario(
                cursoId: cursoRef.id,
                semestreId: semestreRef.id,
                disciplinaId: disciplina.id,
                disciplinaNome: disciplina.nome,
                dia: dia,
                turno: turno,
                sala: sala,
              ).toMap(),
              'teste': true,
            },
          );
        }

        turmas.add((cursoRef.id, daTurma));
        todasDisciplinas.addAll(daTurma);
      }

      await lote.commit();
      registrar('Curso "$nomeCurso": 4 semestres, 16 disciplinas e a grade.');
    }

    // ---------------- ALUNOS E MATRÍCULAS ----------------
    final alunos = await _pessoas(_alunos, PerfilUsuario.aluno);
    var matriculas = 0;
    for (var i = 0; i < alunos.length; i++) {
      // Espalha os alunos pelas 12 turmas (3 cursos x 4 semestres).
      final (cursoId, disciplinas) = turmas[i % turmas.length];
      final lote = _db.batch();
      lote.update(_db.collection('usuarios').doc(alunos[i].id), {
        'cursoId': cursoId,
      });
      for (final d in disciplinas) {
        lote.set(
          _db
              .collection('matriculas')
              .doc(Matricula.idPara(alunos[i].id, d.id)),
          {
            ...Matricula(
              alunoId: alunos[i].id,
              disciplinaId: d.id,
              cursoId: d.cursoId,
              semestreId: d.semestreId,
            ).toMap(),
            'teste': true,
            'criadoEm': FieldValue.serverTimestamp(),
          },
        );
        matriculas++;
      }
      await lote.commit();
    }
    registrar('Alunos prontos: ${alunos.length}, com $matriculas matrículas.');

    // ---------------- RESERVAS (nas salas fora da grade) ----------------
    var reservas = 0;
    if (salasLivres.isEmpty) {
      registrar('Sem salas fora da grade: nenhuma reserva de teste criada.');
    } else {
      final hoje = DateTime.now();
      var dia = DateTime(hoje.year, hoje.month, hoje.day);
      for (var j = 0; reservas < 12 && j < 40; j++) {
        dia = dia.add(const Duration(days: 1));
        if (dia.weekday == DateTime.sunday) continue;

        final sala = salasLivres[j % salasLivres.length];
        final turno = Turno.values[j % Turno.values.length];
        final disciplina = todasDisciplinas[(j * 7) % todasDisciplinas.length];
        final ref = _db
            .collection('reservas')
            .doc(Reserva.idPara(sala, turno, dia));
        // Não passa por cima de uma reserva de verdade.
        if ((await ref.get()).exists) continue;

        await ref.set({
          ...Reserva(
            sala: sala,
            disciplina: disciplina.nome,
            disciplinaId: disciplina.id,
            turno: turno,
            data: dia,
            usuarioId: admin,
          ).toMap(),
          'teste': true,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        reservas++;
      }
      registrar('Reservas criadas: $reservas (em nome do administrador).');
    }

    // ---------------- AVISOS (do administrador) ----------------
    final lote = _db.batch();
    final hoje = DateTime.now();
    for (var i = 0; i < _avisos.length; i++) {
      final (titulo, descricao) = _avisos[i];
      lote.set(_db.collection('avisos').doc(), {
        ...Aviso(
          autorId: admin,
          titulo: titulo,
          descricao: descricao,
          data: DateTime(hoje.year, hoje.month, hoje.day + i * 2),
          hora: TimeOfDay(hour: 8 + (i * 3) % 12, minute: i.isEven ? 0 : 30),
          cor: coresAviso[i % coresAviso.length],
        ).toMap(),
        'teste': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
    await lote.commit();
    registrar('Avisos criados: ${_avisos.length}.');

    registrar(
      'Pronto. As senhas dos usuários de teste são temporárias: '
      'primeiro nome sem acento + 123 (ex.: ana123).',
    );
  }

  /// Garante uma conta para cada nome e devolve os cadastros. Quem já existe
  /// como usuário de teste (de uma geração anterior) é reaproveitado e
  /// reativado, porque o app não consegue apagar contas de login.
  Future<List<Usuario>> _pessoas(
    List<String> nomes,
    PerfilUsuario perfil,
  ) async {
    final colecao = _db.collection('usuarios');
    final prontos = <Usuario>[];

    for (final nome in nomes) {
      final email = emailDeTeste(nome);
      try {
        var achados = await colecao.where('email', isEqualTo: email).get();

        if (achados.docs.isEmpty) {
          await UsuarioService.instancia.cadastrar(
            nome: nome,
            email: email,
            senha: senhaTemporariaPara(nome),
            perfil: perfil,
          );
          achados = await colecao.where('email', isEqualTo: email).get();
          if (achados.docs.isEmpty) continue;
          await achados.docs.first.reference.update({'teste': true});
        } else {
          final dados = achados.docs.first.data();
          // Mesmo e-mail num cadastro de verdade: não mexe.
          if (dados['teste'] != true) {
            registrar('$email já é de um usuário real; pulei.');
            continue;
          }
          await achados.docs.first.reference.update({'ativo': true});
        }

        final doc = await achados.docs.first.reference.get();
        prontos.add(Usuario.fromMap(doc.id, doc.data()!));
      } on ErroCadastro catch (e) {
        registrar('$nome: ${e.mensagem}');
      }
    }
    return prontos;
  }

  Future<void> remover() async {
    final admin = AuthService.usuarioAtual?.uid;
    if (admin == null) throw StateError('Entre como administrador.');

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> deTeste(
      String colecao,
    ) async {
      final r = await _db
          .collection(colecao)
          .where('teste', isEqualTo: true)
          .get();
      return r.docs;
    }

    Future<void> apagar(
      String rotulo,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) async {
      // Lotes de 400: o Firestore aceita até 500 gravações por lote.
      for (var i = 0; i < docs.length; i += 400) {
        final lote = _db.batch();
        for (final doc in docs.skip(i).take(400)) {
          lote.delete(doc.reference);
        }
        await lote.commit();
      }
      registrar('$rotulo removidos: ${docs.length}.');
    }

    // Avisos são pessoais: a consulta precisa ser pelos do próprio autor.
    final avisos = await _db
        .collection('avisos')
        .where('autorId', isEqualTo: admin)
        .get();
    await apagar(
      'Avisos',
      avisos.docs.where((d) => d.data()['teste'] == true).toList(),
    );
    await apagar('Reservas', await deTeste('reservas'));

    // Disciplinas: leva junto a grade e TODAS as matrículas delas, inclusive
    // as que alguém fez à mão durante os testes.
    final disciplinas = await deTeste('disciplinas');
    for (final doc in disciplinas) {
      final lote = _db.batch();
      await FirebaseDisciplinaService.excluirDependentes(lote, doc.id);
      lote.delete(doc.reference);
      await lote.commit();
    }
    registrar(
      'Disciplinas removidas: ${disciplinas.length} '
      '(com a grade e as matrículas).',
    );

    await apagar('Horários', await deTeste('horarios'));
    await apagar('Matrículas', await deTeste('matriculas'));
    await apagar('Semestres', await deTeste('semestres'));
    await apagar('Cursos', await deTeste('cursos'));

    // Contas de login não podem ser apagadas pelo app: ficam desativadas (não
    // entram mais) e são reaproveitadas se os dados forem gerados de novo.
    final usuarios = await deTeste('usuarios');
    for (var i = 0; i < usuarios.length; i += 400) {
      final lote = _db.batch();
      for (final doc in usuarios.skip(i).take(400)) {
        lote.update(doc.reference, {
          'ativo': false,
          'cursoId': FieldValue.delete(),
        });
      }
      await lote.commit();
    }
    registrar('Usuários de teste desativados: ${usuarios.length}.');
    registrar('Pronto. Os dados reais não foram alterados.');
  }
}

// ================================================================
// TELA
// ================================================================

/// Tela do administrador para gerar e remover os dados de teste.
class TelaDadosTeste extends StatefulWidget {
  const TelaDadosTeste({super.key});

  @override
  State<TelaDadosTeste> createState() => _TelaDadosTesteState();
}

class _TelaDadosTesteState extends State<TelaDadosTeste> {
  final List<String> _linhas = [];
  bool _rodando = false;

  Future<void> _rodar(Future<void> Function(DadosTeste) acao) async {
    setState(() {
      _linhas.clear();
      _rodando = true;
    });
    final gerador = DadosTeste((linha) {
      if (mounted) setState(() => _linhas.add(linha));
    });
    try {
      await acao(gerador);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(
          () => _linhas.add(
            e.code == 'permission-denied'
                ? 'Sem permissão. Só o administrador gera dados de teste.'
                : 'Erro do Firebase: ${e.code}. O que já foi criado ficou; '
                      'use "Remover" para limpar.',
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _linhas.add('Erro inesperado: $e'));
    } finally {
      if (mounted) setState(() => _rodando = false);
    }
  }

  Future<void> _confirmarRemocao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Remover dados de teste?',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontWeight: FontWeight.w800,
            color: _azulEscuro,
          ),
        ),
        content: const Text(
          'Apaga os cursos, semestres, disciplinas, grade, matrículas, '
          'reservas e avisos de teste, e desativa os usuários de teste. Os '
          'dados reais não são alterados.',
          style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: _vermelho,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou == true) await _rodar((g) => g.remover());
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            children: [
              const Text(
                'Dados de Teste',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _azulEscuro,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gera 3 cursos (4 semestres e 16 disciplinas cada, com a grade '
                'montada), 6 professores, 20 alunos matriculados, 12 reservas '
                'e 8 avisos. Leva cerca de um minuto, por causa das contas de '
                'login. Tudo fica marcado como teste e pode ser removido depois.',
                style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _rodando ? null : () => _rodar((g) => g.gerar()),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  'Gerar dados de teste',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _rodando ? null : _confirmarRemocao,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text(
                  'Remover dados de teste',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _vermelho,
                  side: const BorderSide(color: _vermelho),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              if (_rodando) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              for (final linha in _linhas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $linha',
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
