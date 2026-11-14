// Testes da viagem com paradas e do estado da navegação (Etapa 3b).
// Cenários BDD: docs/qa/etapa-3b-navegacao.feature

import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/domain/models/shopping.dart';
import 'package:acessa_plus/domain/rules/rotas.dart';
import 'package:acessa_plus/domain/rules/viagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MotorRotas motor;

  setUpAll(() async {
    motor = MotorRotas(
      await JsonCatalogoRepository().pontos(),
      await JsonPercursoRepository().trechos(),
    );
  });

  const semEscadas = CriteriosRota(semEscadas: true);

  test('viagem com parada: Entrada → Elevador → Praça de Alimentação', () {
    final r = motor.calcularViagem('ENT_P', ['ELV_T', 'PA'], semEscadas);
    expect(r, isA<Viagem>());
    r as Viagem;
    expect(r.pernas, hasLength(2));
    expect(r.pernas[0].pontos.last.id, 'ELV_T');
    expect(r.pernas[1].pontos.first.id, 'ELV_T');
    expect(r.pernas[1].pontos.last.id, 'PA');
    expect(r.distanciaM, r.pernas[0].distanciaM + r.pernas[1].distanciaM);
    expect(r.pisos, ['Térreo', '2º piso']);
    expect(r.usaEscada, isFalse);
  });

  test('RN04: parada sem caminho compatível diz qual parada falhou', () {
    final r = motor.calcularViagem('ENT_P', ['PA', 'MEZ'], semEscadas);
    expect(r, isA<ViagemImpossivel>());
    r as ViagemImpossivel;
    expect(r.perna, 1);
    expect(r.de.id, 'PA');
    expect(r.ate.id, 'MEZ');
    expect(r.motivo.existeComEscada, isTrue);
  });

  test('direção no mapa: 0° para cima, 90° para a direita', () {
    PontoReferencia p(double x, double y) => PontoReferencia(
      id: '$x,$y',
      nome: '',
      piso: 'Térreo',
      beacon: '',
      x: x,
      y: y,
      tipo: TipoPonto.corredor,
      saidaEmergencia: false,
    );
    expect(direcaoNoMapa(p(0, 10), p(0, 0)), closeTo(0, .01));
    expect(direcaoNoMapa(p(0, 0), p(10, 0)), closeTo(90, .01));
    expect(direcaoNoMapa(p(0, 0), p(0, 10)), closeTo(180, .01));
    expect(direcaoNoMapa(p(10, 0), p(0, 0)), closeTo(270, .01));
  });

  test('navegação avança beacon a beacon e para em cada parada', () {
    final v =
        motor.calcularViagem('ENT_P', ['ELV_T', 'PA'], semEscadas) as Viagem;
    var s = EstadoNavegacao(v);
    expect(s.pontoAtual.id, 'ENT_P');
    expect(s.restanteM, v.distanciaM);
    expect(s.direcao, isNotNull);

    while (!s.naParada) {
      s = s.chegarAoProximo();
    }
    expect(s.pontoAtual.id, 'ELV_T');
    expect(s.aguardandoSeguir, isTrue);
    expect(s.concluida, isFalse);
    expect(s.proximaParada?.id, 'PA');
    // Na parada, novas detecções não pulam a confirmação do visitante.
    expect(s.chegarAoProximo(), same(s));

    s = s.seguir();
    expect(s.perna, 1);
    expect(s.pontoAtual.id, 'ELV_T');
    // Primeiro passo da 2ª perna é o elevador: sem seta, troca de piso.
    expect(s.etapaAtual?.trecho.trocaPiso, TrocaPiso.elevador);
    expect(s.direcao, isNull);

    while (!s.naParada) {
      s = s.chegarAoProximo();
    }
    expect(s.pontoAtual.id, 'PA');
    expect(s.concluida, isTrue);
    expect(s.progresso, 1);
    expect(s.restanteM, 0);
  });

  test('parada onde o visitante já está conta como chegada imediata', () {
    final v =
        motor.calcularViagem('ELV_T', ['ELV_T', 'PA'], semEscadas) as Viagem;
    final s = EstadoNavegacao(v);
    expect(s.aguardandoSeguir, isTrue);
    expect(s.seguir().etapaAtual, isNotNull);
  });

  test('curva: compara o trecho atual com o anterior', () {
    final r = motor.calcular('ENT_P', 'PNE_T', const CriteriosRota()) as Rota;
    for (var i = 1; i < r.etapas.length; i++) {
      final c = curva(r.etapas[i - 1], r.etapas[i]);
      if (r.etapas[i].trecho.trocaPiso == null) {
        expect(
          c,
          isIn([
            'Siga em frente',
            'Vire à direita',
            'Vire à esquerda',
            'Volte no sentido contrário',
          ]),
        );
      }
    }
    expect(curva(null, r.etapas.first), isNull);
  });

  test('manobra do banner: troca de piso e curvas', () {
    final r = motor.calcular('ENT_P', 'PA', semEscadas) as Rota;
    final elev = r.etapas.indexWhere(
      (e) => e.trecho.trocaPiso == TrocaPiso.elevador,
    );
    expect(manobra(r.etapas[elev - 1], r.etapas[elev]), Manobra.elevador);
    expect(manobra(null, r.etapas.first), Manobra.siga);
    final s = EstadoNavegacao(
      motor.calcularViagem('ENT_P', ['PA'], semEscadas) as Viagem,
    );
    expect(s.etapaSeguinte, same(s.rota.etapas[1]));
  });
}
