import 'package:flutter/material.dart' show TimeOfDay;

import '../model/curso.dart';
import '../model/disciplina.dart';
import '../model/sala.dart';

/// Fonte de dados dos cursos.
///
/// Por enquanto tudo fica em memória, com cursos fictícios, só para as telas
/// funcionarem. Quando o Firestore entrar, é este arquivo que muda.
class CursoService {
  CursoService._();

  static int _proximoId = 5;

  static final List<Curso> _cursos = [
    const Curso(id: '1', nome: 'Sistemas de Informação'),
    const Curso(id: '2', nome: 'Técnico em Informática'),
    const Curso(id: '3', nome: 'Técnico em Administração'),
    const Curso(id: '4', nome: 'Licenciatura em Matemática', ativo: false),
  ];

  static List<Curso> get cursos => List.unmodifiable(_cursos);

  static Curso? buscar(String id) {
    for (final curso in _cursos) {
      if (curso.id == id) return curso;
    }
    return null;
  }

  /// Compara sem diferenciar maiúsculas de minúsculas. [ignorarId] serve para
  /// o curso que está sendo editado não conflitar com ele mesmo.
  static bool nomeJaExiste(String nome, {String? ignorarId}) {
    final procurado = nome.trim().toLowerCase();
    return _cursos.any(
      (curso) =>
          curso.id != ignorarId && curso.nome.trim().toLowerCase() == procurado,
    );
  }

  static Curso adicionar(String nome) {
    final curso = Curso(id: '${_proximoId++}', nome: nome.trim());
    _cursos.add(curso);
    return curso;
  }

  static void editar(String id, String nome) {
    _atualizar(id, (curso) => curso.copyWith(nome: nome.trim()));
  }

  /// Quantos semestres a tela do curso lista.
  /// TODO: virar um campo do [Curso], porque nem todo curso tem 8 semestres.
  static const int semestresPorCurso = 8;

  /// Disciplinas ofertadas em um semestre do curso.
  ///
  /// Dados fictícios só para a tela ter o que mostrar: apenas o curso '1'
  /// (Sistemas de Informação) tem disciplinas, e só em alguns semestres.
  /// Quando o cadastro de disciplinas existir, é aqui que a busca real entra.
  static List<Disciplina> disciplinasDoSemestre(String cursoId, int semestre) {
    if (cursoId != '1') return const [];
    return _disciplinasFicticias[semestre] ?? const [];
  }

  static const Map<int, List<Disciplina>> _disciplinasFicticias = {
    1: [
      Disciplina(
        nome: 'Lógica de Programação',
        professor: 'Ana Souza',
        sala: Sala(numero: '305', tipo: TipoSala.sala, andar: '3º Andar'),
        horarios: [
          HorarioAula(
            dia: DiaSemana.terca,
            inicio: TimeOfDay(hour: 19, minute: 0),
            fim: TimeOfDay(hour: 20, minute: 30),
          ),
        ],
      ),
    ],
    2: [
      Disciplina(
        nome: 'Estrutura de Dados',
        professor: 'Bruno da Silva',
        sala: Sala(numero: '301', tipo: TipoSala.sala, andar: '3º Andar'),
        horarios: [
          HorarioAula(
            dia: DiaSemana.segunda,
            inicio: TimeOfDay(hour: 19, minute: 0),
            fim: TimeOfDay(hour: 20, minute: 30),
          ),
          HorarioAula(
            dia: DiaSemana.quinta,
            inicio: TimeOfDay(hour: 21, minute: 0),
            fim: TimeOfDay(hour: 22, minute: 30),
          ),
        ],
      ),
      Disciplina(
        nome: 'Banco de Dados',
        professor: 'Marcos Lima',
        sala: Sala(
          numero: '402',
          tipo: TipoSala.laboratorio,
          andar: '4º Andar',
        ),
        horarios: [
          HorarioAula(
            dia: DiaSemana.quarta,
            inicio: TimeOfDay(hour: 19, minute: 0),
            fim: TimeOfDay(hour: 22, minute: 30),
          ),
        ],
      ),
    ],
    4: [
      Disciplina(
        nome: 'Engenharia de Software',
        professor: 'Ana Souza',
        sala: Sala(numero: '308', tipo: TipoSala.sala, andar: '3º Andar'),
        horarios: [
          HorarioAula(
            dia: DiaSemana.sexta,
            inicio: TimeOfDay(hour: 19, minute: 0),
            fim: TimeOfDay(hour: 22, minute: 30),
          ),
        ],
      ),
    ],
  };

  static void definirAtivo(String id, bool ativo) {
    _atualizar(id, (curso) => curso.copyWith(ativo: ativo));
  }

  static void _atualizar(String id, Curso Function(Curso) mudar) {
    final indice = _cursos.indexWhere((curso) => curso.id == id);
    if (indice == -1) return;
    _cursos[indice] = mudar(_cursos[indice]);
  }
}
