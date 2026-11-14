// Repositórios de alertas: compartilhamento entre sessões (servidor
// simulado) e cliente HTTP (com MockClient, sem rede).

import 'dart:async';
import 'dart:convert';

import 'package:acessa_plus/data/repositories/http_ocorrencias.dart';
import 'package:acessa_plus/data/repositories/ocorrencias_repositorio.dart';
import 'package:acessa_plus/data/repositories/simulado_ocorrencias.dart';
import 'package:acessa_plus/domain/models/ocorrencia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _relato = NovaOcorrencia(
  shoppingId: 'demo',
  tipo: TipoOcorrencia.pisoMolhado,
  piso: 'Térreo',
  x: 175,
  y: 120,
  pontoId: 'COR_C',
);

Map<String, dynamic> _json(String id, {int confirmacoes = 1}) => {
  'id': id,
  'shoppingId': 'demo',
  'tipo': 'pisoMolhado',
  'piso': 'Térreo',
  'x': 175,
  'y': 120,
  'criadaEm': '2026-11-14T15:00:00.000Z',
  'confirmadaEm': '2026-11-14T15:00:00.000Z',
  'confirmacoes': confirmacoes,
  'resolucoes': 0,
};

http.Response _resp(Object corpo, [int status = 200]) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('servidor simulado com duas sessões', () {
    late ServidorSimulado servidor;
    late SimuladoOcorrenciasRepository a, b;

    setUp(() {
      servidor = ServidorSimulado(
        relogio: () => DateTime.utc(2026, 11, 14, 15),
      );
      a = SimuladoOcorrenciasRepository(servidor, sessao: 'sessao-a');
      b = SimuladoOcorrenciasRepository(servidor, sessao: 'sessao-b');
    });

    test('o que A registra aparece para B sem recarregar', () async {
      final recebidas = <List<Ocorrencia>>[];
      final sub = b.observar('demo').listen(recebidas.add);
      await pumpEventQueue();
      expect(recebidas.single, isEmpty);

      final r = await a.registrar(_relato);
      await pumpEventQueue();
      expect(recebidas.last.map((o) => o.id), [r.ocorrencia.id]);
      expect(a.compartilhado, isFalse); // simulação: a tela avisa
      await sub.cancel();
    });

    test('votos repetidos da mesma sessão não contam', () async {
      final id = (await a.registrar(_relato)).ocorrencia.id;

      expect((await a.confirmar(id)).confirmacoes, 1); // quem relatou
      expect((await b.confirmar(id)).confirmacoes, 2);
      expect((await b.confirmar(id)).confirmacoes, 2);

      final dup = await b.registrar(_relato);
      expect(dup.duplicada, isTrue);
      expect(dup.ocorrencia.confirmacoes, 2);

      expect((await a.marcarResolvida(id)).resolucoes, 1);
      final repetido = await a.marcarResolvida(id);
      expect(repetido.resolucoes, 1);
      expect(repetido.resolvidaEm, isNull);
      expect((await b.marcarResolvida(id)).resolvidaEm, isNotNull);
    });
  });

  group('HttpOcorrenciasRepository', () {
    final base = Uri.parse('http://localhost:8097/api/ocorrencias/');

    test('polling emite a lista, só repete quando muda e cancela', () async {
      var chamadas = 0;
      var lista = [_json('o1')];
      final cliente = MockClient((req) async {
        chamadas++;
        expect(req.method, 'GET');
        expect(req.url.path, '/api/ocorrencias');
        expect(req.url.queryParameters['shopping'], 'demo');
        expect(req.headers['X-Sessao'], 'sessao-teste');
        return _resp({'ocorrencias': lista});
      });
      final repo = HttpOcorrenciasRepository(
        base,
        sessao: 'sessao-teste',
        client: cliente,
        intervalo: const Duration(milliseconds: 10),
      );
      expect(repo.compartilhado, isTrue);

      final recebidas = <List<Ocorrencia>>[];
      final sub = repo.observar('demo').listen(recebidas.add);
      await _ate(() => chamadas >= 3);
      expect(chamadas, greaterThanOrEqualTo(2));
      expect(recebidas, hasLength(1)); // sem mudança, sem nova emissão
      expect(recebidas.single.single.id, 'o1');

      lista = [_json('o1'), _json('o2')];
      await _ate(() => recebidas.length >= 2);
      expect(recebidas, hasLength(2));
      expect(recebidas.last.map((o) => o.id), ['o1', 'o2']);

      await sub.cancel();
      final depois = chamadas;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      // Uma consulta já em andamento pode terminar; depois disso, nada.
      expect(
        chamadas,
        lessThanOrEqualTo(depois + 1),
        reason: 'o Timer para quando o assinante sai',
      );
      repo.fechar();
    });

    test('erro aparece no fluxo como FalhaOcorrencias e recupera', () async {
      var falhar = true;
      final repo = HttpOcorrenciasRepository(
        base,
        sessao: 'sessao-teste',
        client: MockClient((req) async {
          if (falhar) return http.Response('ops', 503);
          return _resp({
            'ocorrencias': [_json('o1')],
          });
        }),
        intervalo: const Duration(milliseconds: 10),
      );
      final eventos = <Object>[];
      final sub = repo
          .observar('demo')
          .listen(eventos.add, onError: (Object e) => eventos.add(e));
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(eventos.first, isA<FalhaOcorrencias>());
      expect(
        (eventos.first as FalhaOcorrencias).mensagem,
        contains('serviço de alertas'),
      );

      falhar = false;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(eventos.last, isA<List<Ocorrencia>>());
      await sub.cancel();
      repo.fechar();
    });

    test('sem resposta no prazo vira falha de tempo', () async {
      final repo = HttpOcorrenciasRepository(
        base,
        sessao: 'sessao-teste',
        client: MockClient(
          (_) => Completer<http.Response>().future, // nunca responde
        ),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        repo.confirmar('o1'),
        throwsA(
          isA<FalhaOcorrencias>().having(
            (f) => f.mensagem,
            'mensagem',
            contains('não respondeu'),
          ),
        ),
      );
      repo.fechar();
    });

    test('registrar envia JSON e entende relato duplicado', () async {
      late http.Request enviada;
      final repo = HttpOcorrenciasRepository(
        base,
        sessao: 'sessao-teste',
        client: MockClient((req) async {
          enviada = req;
          return _resp({
            'ocorrencia': _json('o1', confirmacoes: 2),
            'duplicada': true,
          });
        }),
      );
      final r = await repo.registrar(_relato);
      expect(r.duplicada, isTrue);
      expect(r.ocorrencia.confirmacoes, 2);
      expect(enviada.method, 'POST');
      expect(enviada.url.path, '/api/ocorrencias');
      expect(enviada.headers['X-Sessao'], 'sessao-teste');
      expect(jsonDecode(enviada.body), _relato.toJson());
      repo.fechar();
    });

    test('confirmar e resolver usam /{id}/acao', () async {
      final caminhos = <String>[];
      final repo = HttpOcorrenciasRepository(
        base,
        sessao: 'sessao-teste',
        client: MockClient((req) async {
          caminhos.add('${req.method} ${req.url.path}');
          return _resp({'ocorrencia': _json('o1')});
        }),
      );
      await repo.confirmar('o1');
      await repo.marcarResolvida('o1');
      expect(caminhos, [
        'POST /api/ocorrencias/o1/confirmar',
        'POST /api/ocorrencias/o1/resolver',
      ]);
      repo.fechar();
    });

    test('erros HTTP viram mensagens curtas em português', () async {
      Future<String> mensagem(http.Response r) async {
        final repo = HttpOcorrenciasRepository(
          base,
          sessao: 'sessao-teste',
          client: MockClient((_) async => r),
        );
        try {
          await repo.confirmar('o1');
          fail('deveria falhar');
        } on FalhaOcorrencias catch (f) {
          return f.mensagem;
        } finally {
          repo.fechar();
        }
      }

      expect(
        await mensagem(_resp({'erro': 'Tipo de alerta inválido.'}, 400)),
        'Tipo de alerta inválido.',
      );
      expect(
        await mensagem(http.Response('', 404)),
        'Este alerta não existe mais.',
      );
      expect(await mensagem(http.Response('', 429)), contains('Aguarde'));
      expect(await mensagem(http.Response('<html>', 500)), contains('Tente'));
      expect(
        await mensagem(http.Response('<html>', 200)),
        contains('inválida'),
      );
    });

    test('disponivel confere /saude e aceita só {"ok": true}', () async {
      Future<bool> com(http.Response r) => HttpOcorrenciasRepository.disponivel(
        base,
        client: MockClient((req) async {
          expect(req.url.path, '/api/ocorrencias/saude');
          return r;
        }),
      );
      expect(await com(_resp({'ok': true})), isTrue);
      // Servidor de desenvolvimento que devolve o index.html para tudo.
      expect(await com(http.Response('<!doctype html>', 200)), isFalse);
      expect(await com(http.Response('', 404)), isFalse);
    });
  });
}

/// Espera até [cond] ser verdadeira (máx. 3 s), sem depender da velocidade
/// da máquina.
Future<void> _ate(bool Function() cond) async {
  final fim = DateTime.now().add(const Duration(seconds: 3));
  while (!cond() && DateTime.now().isBefore(fim)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
