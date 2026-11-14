// Regras do mapa colaborativo de alertas, com os dados reais de
// assets/data (pontos e trechos do shopping demonstrativo).

import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/domain/models/ocorrencia.dart';
import 'package:acessa_plus/domain/models/shopping.dart';
import 'package:acessa_plus/domain/rules/ocorrencias.dart';
import 'package:acessa_plus/domain/rules/rotas.dart';
import 'package:acessa_plus/domain/rules/viagem.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 11, 14, 15);

Ocorrencia _alerta(
  TipoOcorrencia tipo,
  double x,
  double y, {
  String id = 'a1',
  String piso = 'Térreo',
  DateTime? em,
  int confirmacoes = 1,
}) => Ocorrencia(
  id: id,
  shoppingId: 'demo',
  tipo: tipo,
  piso: piso,
  x: x,
  y: y,
  criadaEm: em ?? _t0,
  confirmadaEm: em ?? _t0,
  confirmacoes: confirmacoes,
);

NovaOcorrencia _nova(TipoOcorrencia tipo, double x, double y, {String? piso}) =>
    NovaOcorrencia(
      shoppingId: 'demo',
      tipo: tipo,
      piso: piso ?? 'Térreo',
      x: x,
      y: y,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MotorRotas motor;
  late List<PontoReferencia> pontos;
  late List<Local> locais;
  final agora = _t0.add(const Duration(minutes: 10));

  setUpAll(() async {
    pontos = await JsonCatalogoRepository().pontos();
    locais = await JsonCatalogoRepository().locais();
    motor = MotorRotas(pontos, await JsonPercursoRepository().trechos());
  });

  ImpactoAlertas impacto(List<Ocorrencia> l, [DateTime? quando]) =>
      impactoNasRotas(l, motor, pontos, quando ?? agora);

  Set<String> trechosDa(ResultadoRota r) => {
    for (final e in (r as Rota).etapas) e.trecho.id,
  };

  group('trechos afetados', () {
    test('elevador fora de serviço perto de ELV_T bloqueia o T23', () {
      final i = impacto([_alerta(TipoOcorrencia.elevadorParado, 220, 155)]);
      expect(i.bloqueios.keys, contains('T23'));
      expect(i.avisos, isEmpty);
      // O elevador não fecha os corredores em volta.
      expect(i.bloqueios.keys, isNot(contains('T11')));
    });

    test('elevador relatado no 2º piso também afeta o T23', () {
      final i = impacto([
        _alerta(TipoOcorrencia.elevadorParado, 215, 150, piso: '2º piso'),
      ]);
      expect(i.bloqueios.keys, {'T23'});
    });

    test('escada rolante parada afeta o T24 como aviso', () {
      final i = impacto([_alerta(TipoOcorrencia.escadaRolanteParada, 205, 82)]);
      expect(i.avisos.keys, contains('T24'));
      expect(i.bloqueios, isEmpty);
    });

    test('alerta em outro piso não afeta corredores deste piso', () {
      final i = impacto([
        _alerta(TipoOcorrencia.passagemInterditada, 317, 150, piso: '2º piso'),
      ]);
      expect(i.bloqueios.keys, isNot(contains('T21')));
    });
  });

  group('rotas', () {
    test('passagem interditada bloqueia o trecho e a rota desvia', () {
      const c = CriteriosRota();
      final antes = motor.calcular('ENT_P', 'ET', c);
      expect(trechosDa(antes), contains('T13'));

      final i = impacto([
        _alerta(TipoOcorrencia.passagemInterditada, 240, 172),
      ]);
      expect(i.bloqueios.keys, contains('T13'));
      final depois = motor.calcular('ENT_P', 'ET', i.aplicar(c));
      expect(depois, isA<Rota>());
      expect(trechosDa(depois).intersection(i.bloqueios.keys.toSet()), isEmpty);
    });

    test('passagem interditada no único acesso: SemRota explica o alerta', () {
      final i = impacto([
        _alerta(TipoOcorrencia.passagemInterditada, 317, 150),
      ]);
      expect(i.bloqueios.keys, {'T21'});
      final r = motor.calcular('ENT_P', 'ET', i.aplicar(const CriteriosRota()));
      expect(r, isA<SemRota>());
      r as SemRota;
      expect(r.bloqueiosPorAlerta.map((t) => t.id), contains('T21'));
      expect(r.motivo, contains('alerta da comunidade'));
    });

    test('piso molhado encarece o trecho e a rota desvia quando há '
        'alternativa', () {
      final i = impacto([_alerta(TipoOcorrencia.pisoMolhado, 240, 172)]);
      expect(i.bloqueios, isEmpty);
      expect(i.avisos.keys, contains('T13'));
      expect(i.penalidades['T13'], TipoOcorrencia.pisoMolhado.penalidade);

      const c = CriteriosRota();
      final semAlerta = motor.calcular('ENT_P', 'ET', c);
      final comAlerta = motor.calcular('ENT_P', 'ET', i.aplicar(c));
      expect(trechosDa(semAlerta), contains('T13'));
      expect(trechosDa(comAlerta), isNot(contains('T13')));

      final viagemSem =
          motor.calcularViagem('ENT_P', const ['ET'], c) as Viagem;
      final viagemCom = motor.calcularViagem('ENT_P', const [
        'ET',
      ], i.aplicar(c));
      expect(alertasEvitados(viagemSem, viagemCom, i).map((o) => o.id), ['a1']);
    });

    test('piso molhado sem alternativa: segue pelo trecho, com aviso', () {
      final i = impacto([_alerta(TipoOcorrencia.pisoMolhado, 317, 150)]);
      expect(i.avisos.keys, {'T21'});
      final r = motor.calcular('ENT_P', 'ET', i.aplicar(const CriteriosRota()));
      expect(trechosDa(r), contains('T21'));
      final v = motor.calcularViagem('ENT_P', const [
        'ET',
      ], i.aplicar(const CriteriosRota()));
      expect(alertasNaViagem(v as Viagem, i).map((a) => a.ocorrencia.id), [
        'a1',
      ]);
    });

    test('resolvido ou expirado deixa de afetar as rotas', () {
      final elevador = _alerta(TipoOcorrencia.elevadorParado, 215, 150);
      expect(impacto([elevador]).bloqueios, isNotEmpty);

      final resolvido = elevador.copyWith(resolvidaEm: agora);
      expect(impacto([resolvido]).isEmpty, isTrue);

      final depois = _t0.add(TipoOcorrencia.elevadorParado.validade);
      expect(impacto([elevador], depois).isEmpty, isTrue);
      expect(
        motor.calcular(
          'ENT_P',
          'PA',
          impacto([
            elevador,
          ], depois).aplicar(const CriteriosRota(semEscadas: true)),
        ),
        isA<Rota>(),
      );
    });

    test('sem escadas + elevador fora: SemRota com bloqueio por alerta, '
        'nunca rota com escada', () {
      const c = CriteriosRota(semEscadas: true);
      final i = impacto([_alerta(TipoOcorrencia.elevadorParado, 215, 150)]);
      final r = motor.calcular('ENT_P', 'PA', i.aplicar(c));
      expect(r, isA<SemRota>());
      r as SemRota;
      expect(r.bloqueiosPorAlerta.map((t) => t.id), contains('T23'));
      expect(r.existeComEscada, isTrue);

      for (final l in locais.where((l) => l.destino)) {
        for (final origem in ['ENT_P', 'ENT_L', 'EST']) {
          final x = motor.calcular(origem, l.pontoId, i.aplicar(c));
          if (x is Rota) {
            expect(x.usaEscada, isFalse, reason: '$origem → ${l.pontoId}');
            expect(trechosDa(x), isNot(contains('T23')));
          }
        }
      }
    });
  });

  group('duplicado', () {
    final existente = _alerta(TipoOcorrencia.pisoMolhado, 175, 120);

    test('mesmo tipo e piso a até 30 unidades é o mesmo problema', () {
      expect(
        duplicadaDe(
          [existente],
          _nova(TipoOcorrencia.pisoMolhado, 195, 120),
          agora,
        )?.id,
        'a1',
      );
    });

    test('longe, outro tipo, outro piso, outro shopping ou inativo: '
        'não é duplicado', () {
      final n = _nova(TipoOcorrencia.pisoMolhado, 175, 120);
      expect(
        duplicadaDe(
          [existente],
          _nova(TipoOcorrencia.pisoMolhado, 210, 120),
          agora,
        ),
        isNull,
      );
      expect(
        duplicadaDe(
          [existente],
          _nova(TipoOcorrencia.obstaculo, 175, 120),
          agora,
        ),
        isNull,
      );
      expect(
        duplicadaDe(
          [existente],
          _nova(TipoOcorrencia.pisoMolhado, 175, 120, piso: '2º piso'),
          agora,
        ),
        isNull,
      );
      expect(
        duplicadaDe(
          [existente],
          const NovaOcorrencia(
            shoppingId: 'outro',
            tipo: TipoOcorrencia.pisoMolhado,
            piso: 'Térreo',
            x: 175,
            y: 120,
          ),
          agora,
        ),
        isNull,
      );
      expect(
        duplicadaDe([existente.copyWith(resolvidaEm: agora)], n, agora),
        isNull,
      );
      expect(
        duplicadaDe([existente], n, _t0.add(const Duration(hours: 2))),
        isNull,
      );
    });

    test('o mais próximo vence', () {
      final perto = _alerta(TipoOcorrencia.pisoMolhado, 190, 120, id: 'a2');
      expect(
        duplicadaDe(
          [existente, perto],
          _nova(TipoOcorrencia.pisoMolhado, 195, 120),
          agora,
        )?.id,
        'a2',
      );
    });
  });

  group('validade e confirmação', () {
    test('cada tipo expira no seu prazo, contado da última confirmação', () {
      const esperado = {
        TipoOcorrencia.pisoMolhado: 2,
        TipoOcorrencia.passagemInterditada: 8,
        TipoOcorrencia.obstaculo: 2,
        TipoOcorrencia.elevadorParado: 12,
        TipoOcorrencia.escadaRolanteParada: 12,
        TipoOcorrencia.rampaBloqueada: 6,
        TipoOcorrencia.localCheio: 1,
        TipoOcorrencia.outro: 3,
      };
      for (final MapEntry(key: tipo, value: horas) in esperado.entries) {
        final o = _alerta(tipo, 0, 0);
        final fim = _t0.add(Duration(hours: horas));
        expect(expiraEm(o), fim, reason: tipo.name);
        expect(
          situacao(o, fim.subtract(const Duration(seconds: 1))),
          SituacaoOcorrencia.ativa,
        );
        expect(situacao(o, fim), SituacaoOcorrencia.expirada);
      }
    });

    test('"Ainda está aqui" renova o prazo, soma e zera resolução', () {
      final o = votarResolvida(
        _alerta(TipoOcorrencia.pisoMolhado, 0, 0, confirmacoes: 2),
        agora,
      );
      expect(o.resolucoes, 1);
      final depois = _t0.add(const Duration(hours: 1, minutes: 30));
      final c = confirmar(o, depois);
      expect(c.confirmacoes, 3);
      expect(c.resolucoes, 0);
      expect(c.resolvidaEm, isNull);
      expect(expiraEm(c), depois.add(const Duration(hours: 2)));
    });

    test('confirmar um resolvido reabre o alerta', () {
      final r = _alerta(
        TipoOcorrencia.obstaculo,
        0,
        0,
      ).copyWith(resolvidaEm: agora);
      expect(situacao(confirmar(r, agora), agora), SituacaoOcorrencia.ativa);
    });
  });

  group('resolução', () {
    test('com várias confirmações, precisa de 2 votos', () {
      var o = _alerta(TipoOcorrencia.pisoMolhado, 0, 0, confirmacoes: 3);
      o = votarResolvida(o, agora);
      expect(situacao(o, agora), SituacaoOcorrencia.ativa);
      o = votarResolvida(o, agora);
      expect(situacao(o, agora), SituacaoOcorrencia.resolvida);
    });

    test('com uma confirmação só, um voto basta', () {
      final o = votarResolvida(
        _alerta(TipoOcorrencia.pisoMolhado, 0, 0),
        agora,
      );
      expect(o.resolvidaEm, agora);
    });
  });
}
