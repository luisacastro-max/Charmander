import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/shopping.dart';
import 'rotas.dart';

/// Limite de paradas numa viagem (destino final incluído), para a lista
/// continuar curta e fácil de revisar.
const maxParadas = 5;

/// Resultado de uma viagem com uma ou mais paradas, como num app de
/// transporte: origem → parada 1 → parada 2 → … → destino final.
sealed class ResultadoViagem {
  const ResultadoViagem();
}

/// Viagem possível: uma rota (perna) para cada parada, em ordem.
@immutable
class Viagem extends ResultadoViagem {
  const Viagem({required this.pernas, required this.paradas});

  /// `pernas[i]` leva da parada anterior (ou da origem) até `paradas[i]`.
  final List<Rota> pernas;
  final List<PontoReferencia> paradas;

  CriteriosRota get criterios => pernas.first.criterios;
  PontoReferencia get origem => pernas.first.pontos.first;
  PontoReferencia get destinoFinal => paradas.last;

  int get distanciaM => pernas.fold(0, (s, p) => s + p.distanciaM);
  int get minutos => (distanciaM / 50).ceil().clamp(1, 999);
  int get totalEtapas => pernas.fold(0, (s, p) => s + p.etapas.length);
  bool get usaEscada => pernas.any((p) => p.usaEscada);
  bool get usaElevador => pernas.any((p) => p.usaElevador);

  /// Trechos de elevador de toda a viagem, sem repetir (ver
  /// [Rota.trechosDeElevador]).
  List<Trecho> get trechosDeElevador {
    final vistos = <String>{};
    return [
      for (final p in pernas)
        for (final t in p.trechosDeElevador)
          if (vistos.add(t.id)) t,
    ];
  }

  /// Pisos na ordem em que aparecem em toda a viagem.
  List<String> get pisos {
    final r = <String>[];
    for (final p in pernas) {
      for (final piso in p.pisos) {
        if (r.isEmpty || r.last != piso) r.add(piso);
      }
    }
    return r;
  }
}

/// Alguma perna não tem rota compatível (RN04). Informa qual.
@immutable
class ViagemImpossivel extends ResultadoViagem {
  const ViagemImpossivel({
    required this.perna,
    required this.de,
    required this.ate,
    required this.motivo,
  });

  /// Índice da parada que não pode ser alcançada.
  final int perna;
  final PontoReferencia de;
  final PontoReferencia ate;
  final SemRota motivo;
}

extension ViagemNoMotor on MotorRotas {
  /// Calcula a viagem passando por cada parada na ordem dada.
  ResultadoViagem calcularViagem(
    String origem,
    List<String> paradas,
    CriteriosRota c,
  ) {
    assert(paradas.isNotEmpty);
    final pernas = <Rota>[];
    var de = origem;
    for (final (i, ate) in paradas.indexed) {
      final r = calcular(de, ate, c);
      switch (r) {
        case Rota():
          pernas.add(r);
        case SemRota():
          return ViagemImpossivel(
            perna: i,
            de: ponto(de),
            ate: ponto(ate),
            motivo: r,
          );
      }
      de = ate;
    }
    return Viagem(pernas: pernas, paradas: [for (final p in paradas) ponto(p)]);
  }
}

/// Direção no mapa de [de] até [para], em graus: 0 = para cima no mapa,
/// 90 = direita, sentido horário. A "bússola" do app é guiada pelo mapa
/// (decisão MUD-01), não pelo sensor magnético do celular.
double direcaoNoMapa(PontoReferencia de, PontoReferencia para) {
  final dx = para.x - de.x, dy = para.y - de.y;
  if (dx == 0 && dy == 0) return 0;
  final g = math.atan2(dx, -dy) * 180 / math.pi;
  return (g + 360) % 360;
}

/// Manobra da etapa, como no banner de um GPS.
enum Manobra {
  siga,
  frente,
  direita,
  esquerda,
  retorno,
  elevador,
  escadaRolante,
  escada,
  rampa,
}

/// Manobra de [atual] em relação ao trecho anterior. Sem trecho anterior
/// no mesmo piso, é só [Manobra.siga].
Manobra manobra(EtapaRota? anterior, EtapaRota atual) {
  switch (atual.trecho.trocaPiso) {
    case TrocaPiso.elevador:
      return Manobra.elevador;
    case TrocaPiso.escadaRolante:
      return Manobra.escadaRolante;
    case TrocaPiso.escada:
      return Manobra.escada;
    case TrocaPiso.rampa:
      return Manobra.rampa;
    case null:
      break;
  }
  if (anterior == null || anterior.trecho.trocaPiso != null) {
    return Manobra.siga;
  }
  final a = direcaoNoMapa(anterior.de, anterior.para);
  final b = direcaoNoMapa(atual.de, atual.para);
  final d = ((b - a + 540) % 360) - 180; // -180..180
  if (d.abs() < 35) return Manobra.frente;
  if (d.abs() > 145) return Manobra.retorno;
  return d > 0 ? Manobra.direita : Manobra.esquerda;
}

/// Orientação curta em relação ao trecho anterior ("Vire à direita").
/// `null` quando não há trecho anterior no mesmo piso para comparar.
String? curva(EtapaRota? anterior, EtapaRota atual) =>
    switch (manobra(anterior, atual)) {
      Manobra.frente => 'Siga em frente',
      Manobra.retorno => 'Volte no sentido contrário',
      Manobra.direita => 'Vire à direita',
      Manobra.esquerda => 'Vire à esquerda',
      _ => null,
    };

/// Estado da navegação passo a passo. Imutável: cada chegada a um beacon
/// (simulada) gera um novo estado.
@immutable
class EstadoNavegacao {
  const EstadoNavegacao(this.viagem, {this.perna = 0, this.passo = 0});

  final Viagem viagem;

  /// Parada para onde o visitante está indo agora.
  final int perna;

  /// Etapas já concluídas dentro da perna atual.
  final int passo;

  Rota get rota => viagem.pernas[perna];
  PontoReferencia get pontoAtual => rota.pontos[passo];
  PontoReferencia get paradaAtual => viagem.paradas[perna];

  /// Chegou à parada da perna atual.
  bool get naParada => passo >= rota.etapas.length;
  bool get ultimaPerna => perna == viagem.pernas.length - 1;
  bool get concluida => naParada && ultimaPerna;

  /// Chegou a uma parada intermediária e espera o visitante seguir.
  bool get aguardandoSeguir => naParada && !ultimaPerna;

  EtapaRota? get etapaAtual => naParada ? null : rota.etapas[passo];
  EtapaRota? get etapaAnterior => passo == 0 ? null : rota.etapas[passo - 1];
  PontoReferencia? get proximoPonto => etapaAtual?.para;

  /// Etapa depois da atual na mesma perna ("Depois: …" do GPS).
  EtapaRota? get etapaSeguinte =>
      passo + 1 < rota.etapas.length ? rota.etapas[passo + 1] : null;

  PontoReferencia? get proximaParada =>
      ultimaPerna ? null : viagem.paradas[perna + 1];

  /// Seta da bússola: direção no mapa até o próximo ponto. `null` em troca
  /// de piso (o ponto de chegada fica "em cima" do de saída).
  double? get direcao {
    final e = etapaAtual;
    if (e == null || e.trecho.trocaPiso != null) return null;
    return direcaoNoMapa(e.de, e.para);
  }

  int get etapasFeitas {
    var n = passo;
    for (var i = 0; i < perna; i++) {
      n += viagem.pernas[i].etapas.length;
    }
    return n;
  }

  double get progresso =>
      viagem.totalEtapas == 0 ? 1 : etapasFeitas / viagem.totalEtapas;

  /// Metros que faltam até o destino final.
  int get restanteM {
    var m = 0;
    for (var e = passo; e < rota.etapas.length; e++) {
      m += rota.etapas[e].trecho.distanciaM;
    }
    for (var i = perna + 1; i < viagem.pernas.length; i++) {
      m += viagem.pernas[i].distanciaM;
    }
    return m;
  }

  /// Metros que faltam até a parada atual.
  int get restanteParadaM {
    var m = 0;
    for (var e = passo; e < rota.etapas.length; e++) {
      m += rota.etapas[e].trecho.distanciaM;
    }
    return m;
  }

  /// O celular detectou o beacon do próximo ponto (simulado).
  EstadoNavegacao chegarAoProximo() =>
      naParada ? this : EstadoNavegacao(viagem, perna: perna, passo: passo + 1);

  /// Sai da parada intermediária rumo à próxima.
  EstadoNavegacao seguir() =>
      aguardandoSeguir ? EstadoNavegacao(viagem, perna: perna + 1) : this;
}
