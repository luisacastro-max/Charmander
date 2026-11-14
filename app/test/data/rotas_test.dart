// Testes do motor de rotas (Etapa 3a).
// Cenários BDD: docs/qa/etapa-3a-destino.feature

import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/domain/models/shopping.dart';
import 'package:acessa_plus/domain/rules/rotas.dart';
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

  test('RN03: com "sem escadas", nenhuma rota usa trecho com escada', () {
    final destinos = locais.where((l) => l.destino).map((l) => l.pontoId);
    for (final origem in ['ENT_P', 'ENT_L', 'EST', 'PA']) {
      for (final d in destinos) {
        final r = motor.calcular(origem, d, semEscadas);
        if (r is Rota) {
          expect(r.usaEscada, isFalse, reason: '$origem → $d');
        }
      }
    }
  });

  test('sem escadas, a Praça de Alimentação é alcançada pelo elevador', () {
    final r = motor.calcular('ENT_P', 'PA', semEscadas);
    expect(r, isA<Rota>());
    r as Rota;
    expect(r.usaElevador, isTrue);
    expect(r.pisos, ['Térreo', '2º piso']);
  });

  test('sem restrição, a rota mais curta até o Sabor da Terra usa a escada rolante', () {
    final r = motor.calcular('ENT_P', 'RES1', const CriteriosRota()) as Rota;
    expect(r.usaEscada, isTrue);
  });

  test('preferência por elevador muda a rota quando há escada (bug do '
      'protótipo corrigido)', () {
    final r = motor.calcular(
      'ENT_P',
      'RES1',
      const CriteriosRota(preferirElevador: true),
    ) as Rota;
    expect(r.usaElevador, isTrue);
    expect(
      r.etapas.any((e) => e.trecho.trocaPiso == TrocaPiso.escadaRolante),
      isFalse,
    );
  });

  test('RN04: destino só acessível por escada informa a limitação sem '
      'remover a restrição', () {
    final r = motor.calcular('ENT_P', 'MEZ', semEscadas);
    expect(r, isA<SemRota>());
    r as SemRota;
    expect(r.existeComEscada, isTrue);
    expect(r.motivo, contains('sem escadas'));
  });

  test(
    'caminho tranquilo evita trechos com muito movimento quando possível',
    () {
      final normal =
          motor.calcular('ENT_P', 'FAM', const CriteriosRota()) as Rota;
      final calmo = motor.calcular(
        'ENT_P',
        'FAM',
        const CriteriosRota(caminhoTranquilo: true),
      ) as Rota;
      int altos(Rota r) =>
          r.etapas.where((e) => e.trecho.movimento == Movimento.alto).length;
      expect(altos(calmo), lessThanOrEqualTo(altos(normal)));
    },
  );

  test('etapas encadeadas e com instrução em texto (RF18)', () {
    final r = motor.calcular('EST', 'PNE_2', semEscadas) as Rota;
    expect(r.pontos.first.id, 'EST');
    expect(r.pontos.last.id, 'PNE_2');
    for (var i = 0; i < r.etapas.length; i++) {
      expect(r.etapas[i].de.id, r.pontos[i].id);
      expect(r.etapas[i].para.id, r.pontos[i + 1].id);
      expect(r.etapas[i].instrucao, isNotEmpty);
    }
    expect(r.distanciaM, greaterThan(0));
    expect(r.minutos, greaterThanOrEqualTo(1));
  });

  test('origem igual ao destino: rota vazia', () {
    final r = motor.calcular('PA', 'PA', semEscadas) as Rota;
    expect(r.etapas, isEmpty);
  });
}
