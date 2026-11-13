// Testes dos dados fictícios e das regras de dados (Etapa 2).
// Cenários BDD: docs/qa/etapa-2-fundacao.feature

import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/domain/models/shopping.dart';
import 'package:acessa_plus/domain/rules/informacao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalogo = JsonCatalogoRepository();
  final percursos = JsonPercursoRepository();
  final comunicacao = JsonComunicacaoRepository();

  group('Catálogo', () {
    test('carrega 9 pontos com beacons simulados únicos', () async {
      final pontos = await catalogo.pontos();
      expect(pontos, hasLength(9));
      expect(pontos.map((p) => p.beacon).toSet(), hasLength(9));
    });

    test('todo local aponta para um ponto existente', () async {
      final ids = (await catalogo.pontos()).map((p) => p.id).toSet();
      for (final l in await catalogo.locais()) {
        expect(ids, contains(l.pontoId), reason: l.nome);
      }
    });

    test('a escada não pode ser escolhida como destino', () async {
      final esc = (await catalogo.locais()).firstWhere((l) => l.id == 'ESC');
      expect(esc.destino, isFalse);
    });

    test('há saída de emergência e todas ficam no térreo (RF53)', () async {
      final saidas = (await catalogo.pontos()).where((p) => p.saidaEmergencia);
      expect(saidas, isNotEmpty);
      expect(saidas.every((p) => p.piso == 'Térreo'), isTrue);
    });
  });

  group('Percursos', () {
    test('todo trecho liga dois pontos existentes', () async {
      final ids = (await catalogo.pontos()).map((p) => p.id).toSet();
      for (final t in await percursos.trechos()) {
        expect(ids, containsAll([t.de, t.para]), reason: t.id);
      }
    });

    test('RN03: todo trecho que chega à escada está marcado com escada',
        () async {
      final escadas = (await catalogo.pontos())
          .where((p) => p.tipo == TipoPonto.escada)
          .map((p) => p.id)
          .toSet();
      for (final t in await percursos.trechos()) {
        if (escadas.contains(t.de) || escadas.contains(t.para)) {
          expect(t.escada, isTrue, reason: '${t.id} toca a escada');
        }
      }
    });

    test('toda troca de piso diz como acontece', () async {
      final piso = {for (final p in await catalogo.pontos()) p.id: p.piso};
      for (final t in await percursos.trechos()) {
        if (piso[t.de] != piso[t.para]) {
          expect(t.trocaPiso, isNotNull, reason: t.id);
        }
      }
    });

    test('existe ligação sem escada entre os pisos, pelo elevador', () async {
      final semEscada = (await percursos.trechos()).where((t) => !t.escada);
      expect(semEscada.any((t) => t.trocaPiso == TrocaPiso.elevador), isTrue);
    });
  });

  group('Comunicação', () {
    test('8 cartões, 6 categorias e 6 frases em 3 idiomas', () async {
      expect(await comunicacao.cartoes(), hasLength(8));
      expect(await comunicacao.mensagensRapidas(), hasLength(6));
      final frases = await comunicacao.frasesTraduzidas();
      expect(frases, hasLength(6));
      for (final f in frases) {
        expect([f.pt, f.en, f.es].every((s) => s.trim().isNotEmpty), isTrue);
      }
    });

    test('RN14: toda sugestão prepara mensagem ou ativa preferência',
        () async {
      for (final s in await comunicacao.sugestoesPorPonto()) {
        for (final a in s.acoes) {
          expect(a.mensagem != null || a.ativarPreferencia != null, isTrue,
              reason: '${s.pontoId}: ${a.titulo}');
        }
      }
    });
  });

  group('RNF08/RN06: informação desconhecida', () {
    test('texto ausente ou vazio vira "Não informado"', () {
      expect(exibir(null), naoInformado);
      expect(exibir('   '), naoInformado);
      expect(exibir('10h às 22h'), '10h às 22h');
    });

    test('recursos ausentes ou vazios viram "Não informado"', () {
      expect(exibirRecursos(null), [naoInformado]);
      expect(exibirRecursos(const []), [naoInformado]);
      expect(exibirRecursos(const ['Braille']), ['Braille']);
    });

    test('dados do catálogo: horário e recursos ausentes', () async {
      final locais = await catalogo.locais();
      final banheiro = locais.firstWhere((l) => l.id == 'BAN');
      expect(exibir(banheiro.horario), naoInformado);
      final escada = locais.firstWhere((l) => l.id == 'ESC');
      expect(exibirRecursos(escada.recursos), [naoInformado]);
    });
  });
}
