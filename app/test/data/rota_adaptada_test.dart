// Rota adaptada x rota mais usada, e indisponibilidade simulada
// (ex.: elevador em manutenção). Pedido do mentor: mostrar que a rota muda
// conforme a acessibilidade.

import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/domain/models/shopping.dart';
import 'package:acessa_plus/domain/rules/rota_adaptada.dart';
import 'package:acessa_plus/domain/rules/rotas.dart';
import 'package:acessa_plus/domain/rules/viagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MotorRotas motor;
  late List<Local> locais;

  setUpAll(() async {
    motor = MotorRotas(
      await JsonCatalogoRepository().pontos(),
      await JsonPercursoRepository().trechos(),
    );
    locais = await JsonCatalogoRepository().locais();
  });

  const semEscadas = CriteriosRota(semEscadas: true);

  bool usaEscadaRolante(Rota r) =>
      r.etapas.any((e) => e.trecho.trocaPiso == TrocaPiso.escadaRolante);

  group('cadeira de rodas até a Praça de Alimentação (2º piso)', () {
    late ComparacaoRota c;
    setUp(() {
      c = motor.compararRota('ENT_P', 'PA', semEscadas) as ComparacaoRota;
    });

    test('rota mais usada sobe pela escada rolante', () {
      expect(usaEscadaRolante(c.principal), isTrue);
      expect(c.principal.usaElevador, isFalse);
    });

    test('rota adaptada dá a volta pelo elevador e é mais longa', () {
      expect(c.mudou, isTrue);
      expect(c.adaptada.usaElevador, isTrue);
      expect(c.adaptada.usaEscada, isFalse);
      expect(c.adaptada.distanciaM, greaterThan(c.principal.distanciaM));
    });

    test('desvio em metros e minutos', () {
      expect(c.extraM, c.adaptada.distanciaM - c.principal.distanciaM);
      // Desvio visível na demonstração, sem ser absurdo.
      expect(c.extraM, inInclusiveRange(25, 50));
      expect(c.extraMin, c.adaptada.minutos - c.principal.minutos);
      expect(c.extraMin, greaterThanOrEqualTo(1));
    });

    test('obstáculo evitado é a escada rolante; substituto é o elevador', () {
      expect(c.obstaculosEvitados, hasLength(1));
      expect(
        c.obstaculosEvitados.single.trecho.trocaPiso,
        TrocaPiso.escadaRolante,
      );
      expect(c.substitutos, hasLength(1));
      expect(c.substitutos.single.trecho.trocaPiso, TrocaPiso.elevador);
    });
  });

  test('sem restrição pessoal, a rota não muda', () {
    const nenhum = CriteriosRota();
    expect(nenhum.temRestricao, isFalse);
    final c = motor.compararRota('ENT_P', 'PA', nenhum) as ComparacaoRota;
    expect(c.mudou, isFalse);
    expect(c.extraM, 0);
    expect(c.extraMin, 0);
    expect(c.obstaculosEvitados, isEmpty);
    expect(c.substitutos, isEmpty);
  });

  test('viagem com paradas compara perna a perna', () {
    final c = motor.compararViagem('ENT_P', [
      'LJ3',
      'PA',
    ], semEscadas) as ComparacaoViagem;
    expect(c.pernas, hasLength(2));
    expect(c.pernas[0].mudou, isFalse); // Térreo, sem escada no caminho
    expect(c.pernas[1].mudou, isTrue);
    expect(c.mudou, isTrue);
    expect(c.extraM, c.pernas[0].extraM + c.pernas[1].extraM);
    expect(
      c.obstaculosEvitados.single.trecho.trocaPiso,
      TrocaPiso.escadaRolante,
    );
    expect(c.substitutos.single.trecho.trocaPiso, TrocaPiso.elevador);
  });

  group('elevador em manutenção (simulado)', () {
    late Rota adaptada;
    late CriteriosRota emManutencao;
    setUp(() {
      adaptada = motor.calcular('ENT_P', 'PA', semEscadas) as Rota;
      emManutencao = semEscadas.copyWith(
        indisponiveis: {for (final t in adaptada.trechosDeElevador) t.id},
      );
    });

    test('a rota informa quais trechos de elevador usa', () {
      expect(adaptada.trechosDeElevador, isNotEmpty);
      expect(
        adaptada.trechosDeElevador.every(
          (t) => t.trocaPiso == TrocaPiso.elevador,
        ),
        isTrue,
      );
      final v =
          motor.calcularViagem('ENT_P', ['LJ3', 'PA'], semEscadas) as Viagem;
      expect(
        v.trechosDeElevador.map((t) => t.id),
        adaptada.trechosDeElevador.map((t) => t.id),
      );
    });

    test('sem escadas vira SemRota citando o elevador em manutenção', () {
      final r = motor.calcular('ENT_P', 'PA', emManutencao);
      expect(r, isA<SemRota>());
      r as SemRota;
      expect(r.existeComEscada, isTrue);
      expect(
        r.bloqueios.map((t) => t.id),
        adaptada.trechosDeElevador.map((t) => t.id),
      );
      expect(r.motivo, contains('sem escadas'));
      expect(r.motivo, contains('manutenção'));
      expect(r.motivo, contains('Elevadores'));

      final c = motor.compararRota('ENT_P', 'PA', emManutencao);
      expect(c, isA<RotaAdaptadaImpossivel>());
      c as RotaAdaptadaImpossivel;
      // A rota mais usada continua existindo (escada rolante).
      expect(c.principal, isA<Rota>());
      expect(usaEscadaRolante(c.principal as Rota), isTrue);
    });

    test('quem não tem restrição segue pela escada rolante', () {
      final r = motor.calcular(
        'ENT_P',
        'PA',
        CriteriosRota(indisponiveis: emManutencao.indisponiveis),
      );
      expect(r, isA<Rota>());
      expect((r as Rota).trechosDeElevador, isEmpty);
    });

    test('nenhuma rota usa trecho indisponível', () {
      final destinos = locais.where((l) => l.destino).map((l) => l.pontoId);
      for (final c in [
        CriteriosRota(indisponiveis: emManutencao.indisponiveis),
        emManutencao,
      ]) {
        for (final d in destinos) {
          final r = motor.calcular('ENT_P', d, c);
          if (r is Rota) {
            expect(
              r.etapas.any((e) => c.indisponiveis.contains(e.trecho.id)),
              isFalse,
              reason: 'ENT_P → $d',
            );
          }
        }
      }
    });
  });

  test('RN03 preservada: rota adaptada sem escadas nunca usa escada', () {
    final destinos = locais.where((l) => l.destino).map((l) => l.pontoId);
    for (final origem in ['ENT_P', 'ENT_L', 'EST', 'PA']) {
      for (final d in destinos) {
        final c = motor.compararRota(origem, d, semEscadas);
        if (c is ComparacaoRota) {
          expect(c.adaptada.usaEscada, isFalse, reason: '$origem → $d');
          expect(c.extraM, greaterThanOrEqualTo(0), reason: '$origem → $d');
        }
      }
    }
    // Mezanino continua só por escada (RN04).
    final mez = motor.compararRota('ENT_P', 'MEZ', semEscadas);
    expect(mez, isA<RotaAdaptadaImpossivel>());
    expect((mez as RotaAdaptadaImpossivel).motivo.existeComEscada, isTrue);
    expect(mez.motivo.bloqueios, isEmpty);
  });

  test('critérios: igualdade por valor, inclusive indisponíveis', () {
    expect(
      const CriteriosRota(semEscadas: true, indisponiveis: {'T23'}),
      CriteriosRota(semEscadas: true, indisponiveis: {'T23'}),
    );
    expect(
      const CriteriosRota(semEscadas: true),
      isNot(const CriteriosRota(semEscadas: true, indisponiveis: {'T23'})),
    );
    expect(
      const CriteriosRota(
        semEscadas: true,
        indisponiveis: {'T23'},
      ).semPreferencias,
      const CriteriosRota(indisponiveis: {'T23'}),
    );
  });
}
