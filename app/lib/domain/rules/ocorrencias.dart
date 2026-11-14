import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/ocorrencia.dart';
import '../models/shopping.dart';
import 'rotas.dart';
import 'viagem.dart';

/// Regras do mapa colaborativo de alertas (relatos da comunidade).
///
/// Funções puras: as mesmas regras valem no modo simulado e servem de
/// referência para o servidor (`.claude/api-ocorrencias.js`), que as repete
/// para ser a fonte da verdade quando há compartilhamento real.

/// Distância (unidades da planta) abaixo da qual dois relatos do mesmo tipo
/// e piso são tratados como o mesmo problema.
const raioDuplicado = 30.0;

/// Distância máxima de um alerta até um trecho de corredor para afetá-lo.
const raioTrecho = 22.0;

/// Distância máxima até o ponto de um elevador/escada rolante/rampa.
const raioEquipamento = 40.0;

/// Quantas pessoas precisam dizer "Já foi resolvido" (no máximo; se só uma
/// pessoa relatou, basta uma).
const resolucoesNecessarias = 2;

DateTime expiraEm(Ocorrencia o) => o.confirmadaEm.add(o.tipo.validade);

SituacaoOcorrencia situacao(Ocorrencia o, DateTime agora) {
  if (o.resolvidaEm != null) return SituacaoOcorrencia.resolvida;
  if (!agora.isBefore(expiraEm(o))) return SituacaoOcorrencia.expirada;
  return SituacaoOcorrencia.ativa;
}

bool estaAtiva(Ocorrencia o, DateTime agora) =>
    situacao(o, agora) == SituacaoOcorrencia.ativa;

List<Ocorrencia> ativas(Iterable<Ocorrencia> l, DateTime agora) => [
  for (final o in l)
    if (estaAtiva(o, agora)) o,
];

double _dist(double ax, double ay, double bx, double by) =>
    math.sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));

/// Alerta ativo que já descreve o mesmo problema do relato [n]: mesmo
/// shopping, tipo e piso, a até [raioDuplicado]. O mais próximo vence.
/// Um relato duplicado vira confirmação do existente.
Ocorrencia? duplicadaDe(
  Iterable<Ocorrencia> existentes,
  NovaOcorrencia n,
  DateTime agora,
) {
  Ocorrencia? melhor;
  var menor = double.infinity;
  for (final o in existentes) {
    if (o.shoppingId != n.shoppingId ||
        o.tipo != n.tipo ||
        o.piso != n.piso ||
        !estaAtiva(o, agora)) {
      continue;
    }
    final d = _dist(o.x, o.y, n.x, n.y);
    if (d <= raioDuplicado && d < menor) {
      menor = d;
      melhor = o;
    }
  }
  return melhor;
}

/// "Ainda está aqui": renova o prazo, conta mais uma pessoa e zera os
/// votos de resolução (há evidência nova de que o problema continua).
Ocorrencia confirmar(Ocorrencia o, DateTime agora) => o.copyWith(
  confirmadaEm: agora,
  confirmacoes: o.confirmacoes + 1,
  resolucoes: 0,
  limparResolvida: true,
);

/// "Já foi resolvido": conta um voto. Fica resolvido com
/// min([resolucoesNecessarias], confirmações) votos — se só quem relatou
/// viu o problema, uma pessoa basta.
Ocorrencia votarResolvida(Ocorrencia o, DateTime agora) {
  final votos = o.resolucoes + 1;
  final precisa = math.min(resolucoesNecessarias, o.confirmacoes);
  return o.copyWith(
    resolucoes: votos,
    resolvidaEm: votos >= precisa ? agora : null,
  );
}

/// Ponto de referência mais próximo de (x, y) no [piso].
PontoReferencia? pontoMaisProximo(
  Iterable<PontoReferencia> pontos,
  String piso,
  double x,
  double y,
) {
  PontoReferencia? melhor;
  var menor = double.infinity;
  for (final p in pontos) {
    if (p.piso != piso) continue;
    final d = _dist(p.x, p.y, x, y);
    if (d < menor) {
      menor = d;
      melhor = p;
    }
  }
  return melhor;
}

double _distSegmento(Offset2 p, Offset2 a, Offset2 b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final l2 = dx * dx + dy * dy;
  if (l2 == 0) return _dist(p.x, p.y, a.x, a.y);
  final t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / l2).clamp(0.0, 1.0);
  return _dist(p.x, p.y, a.x + t * dx, a.y + t * dy);
}

/// Par (x, y) simples, sem depender de dart:ui nas regras.
typedef Offset2 = ({double x, double y});

/// Trechos do grafo afetados pelo alerta [o].
///
/// - Elevador / escada rolante / rampa: trechos de troca de piso desse
///   tipo cujo ponto, no piso do alerta, fica a até [raioEquipamento].
///   Sem rampa cadastrada perto, a "rampa bloqueada" afeta o corredor mais
///   próximo (como uma passagem interditada).
/// - Demais: trechos de corredor do mesmo piso a até [raioTrecho]; se
///   nenhum, o mais próximo a até 2×[raioTrecho].
Set<String> trechosAfetados(
  Ocorrencia o,
  Map<String, PontoReferencia> pontos,
  List<Trecho> trechos,
) {
  final alvo = (x: o.x, y: o.y);
  Set<String> porEquipamento(TrocaPiso troca) => {
    for (final t in trechos)
      if (t.trocaPiso == troca)
        for (final id in [t.de, t.para])
          if (pontos[id] case final p?
              when p.piso == o.piso &&
                  _dist(p.x, p.y, o.x, o.y) <= raioEquipamento)
            t.id,
  };

  switch (o.tipo) {
    case TipoOcorrencia.elevadorParado:
      return porEquipamento(TrocaPiso.elevador);
    case TipoOcorrencia.escadaRolanteParada:
      return porEquipamento(TrocaPiso.escadaRolante);
    case TipoOcorrencia.rampaBloqueada:
      final r = porEquipamento(TrocaPiso.rampa);
      if (r.isNotEmpty) return r;
    default:
  }

  final perto = <String>{};
  String? maisProximo;
  var menor = double.infinity;
  for (final t in trechos) {
    if (t.trocaPiso != null) continue;
    final a = pontos[t.de], b = pontos[t.para];
    if (a == null || b == null || a.piso != o.piso || b.piso != o.piso) {
      continue;
    }
    final d = _distSegmento(alvo, (x: a.x, y: a.y), (x: b.x, y: b.y));
    if (d <= raioTrecho) perto.add(t.id);
    if (d < menor) {
      menor = d;
      maisProximo = t.id;
    }
  }
  if (perto.isEmpty && maisProximo != null && menor <= raioTrecho * 2) {
    perto.add(maisProximo);
  }
  return perto;
}

/// Como os alertas ativos mudam as rotas.
@immutable
class ImpactoAlertas {
  const ImpactoAlertas({
    this.bloqueios = const {},
    this.avisos = const {},
    this.porOcorrencia = const {},
  });

  static const vazio = ImpactoAlertas();

  /// Trecho → alertas que o bloqueiam.
  final Map<String, List<Ocorrencia>> bloqueios;

  /// Trecho → alertas que pedem cuidado nele.
  final Map<String, List<Ocorrencia>> avisos;

  /// Alerta → trechos que ele afeta.
  final Map<String, Set<String>> porOcorrencia;

  bool get isEmpty => bloqueios.isEmpty && avisos.isEmpty;

  /// Multiplicador de custo por trecho (o maior entre os avisos).
  Map<String, double> get penalidades => {
    for (final e in avisos.entries)
      e.key: e.value.map((o) => o.tipo.penalidade).reduce(math.max),
  };

  /// Critérios [c] com os alertas aplicados.
  CriteriosRota aplicar(CriteriosRota c) => c.copyWith(
    bloqueadosPorAlerta: bloqueios.keys.toSet(),
    penalidades: penalidades,
  );

  /// Alertas (bloqueio ou aviso) num trecho.
  List<Ocorrencia> doTrecho(String trechoId) => [
    ...?bloqueios[trechoId],
    ...?avisos[trechoId],
  ];
}

/// Calcula o impacto dos alertas **ativos** em [agora] (resolvidos e
/// expirados não afetam nada).
ImpactoAlertas impactoNasRotas(
  Iterable<Ocorrencia> ocorrencias,
  MotorRotas motor,
  List<PontoReferencia> pontos,
  DateTime agora,
) {
  final porId = {for (final p in pontos) p.id: p};
  final bloqueios = <String, List<Ocorrencia>>{};
  final avisos = <String, List<Ocorrencia>>{};
  final porOcorrencia = <String, Set<String>>{};
  for (final o in ativas(ocorrencias, agora)) {
    final afetados = trechosAfetados(o, porId, motor.trechos);
    porOcorrencia[o.id] = afetados;
    final destino = o.tipo.efeito == EfeitoOcorrencia.bloqueia
        ? bloqueios
        : avisos;
    for (final t in afetados) {
      (destino[t] ??= []).add(o);
    }
  }
  return ImpactoAlertas(
    bloqueios: bloqueios,
    avisos: avisos,
    porOcorrencia: porOcorrencia,
  );
}

/// Um alerta num trecho que a viagem usa.
@immutable
class AlertaNoCaminho {
  const AlertaNoCaminho({required this.etapa, required this.ocorrencia});
  final EtapaRota etapa;
  final Ocorrencia ocorrencia;
}

/// Alertas nos trechos das [etapas], na ordem do caminho, sem repetir.
List<AlertaNoCaminho> alertasNasEtapas(
  Iterable<EtapaRota> etapas,
  ImpactoAlertas impacto,
) {
  final vistos = <String>{};
  return [
    for (final e in etapas)
      for (final o in impacto.doTrecho(e.trecho.id))
        if (vistos.add(o.id)) AlertaNoCaminho(etapa: e, ocorrencia: o),
  ];
}

List<AlertaNoCaminho> alertasNaViagem(Viagem v, ImpactoAlertas impacto) =>
    alertasNasEtapas([for (final p in v.pernas) ...p.etapas], impacto);

/// Etapas que ainda faltam na navegação (da atual em diante).
List<EtapaRota> etapasRestantes(EstadoNavegacao e) => [
  for (var i = e.passo; i < e.rota.etapas.length; i++) e.rota.etapas[i],
  for (var p = e.perna + 1; p < e.viagem.pernas.length; p++)
    ...e.viagem.pernas[p].etapas,
];

/// Alertas no caminho que falta e que o visitante ainda não viu
/// ([conhecidos] = ids já avisados). Usado para oferecer o recálculo.
List<AlertaNoCaminho> novosAlertasNoCaminho(
  EstadoNavegacao e,
  ImpactoAlertas impacto,
  Set<String> conhecidos,
) => [
  for (final a in alertasNasEtapas(etapasRestantes(e), impacto))
    if (!conhecidos.contains(a.ocorrencia.id)) a,
];

/// O caminho que falta passa por um trecho bloqueado por alerta.
bool caminhoBloqueado(EstadoNavegacao e, ImpactoAlertas impacto) =>
    etapasRestantes(e).any((x) => impacto.bloqueios.containsKey(x.trecho.id));

/// Paradas que faltam (a atual em diante), para recalcular do ponto atual.
List<String> paradasRestantes(EstadoNavegacao e) => [
  for (var p = e.perna; p < e.viagem.paradas.length; p++)
    e.viagem.paradas[p].id,
];

/// Recalcula a viagem do ponto atual até as paradas que faltam, com os
/// critérios [c] (já com os alertas aplicados).
ResultadoViagem recalcularDaqui(
  MotorRotas motor,
  EstadoNavegacao e,
  CriteriosRota c,
) => motor.calcularViagem(e.pontoAtual.id, paradasRestantes(e), c);

/// Compara a viagem com e sem alertas: quais alertas a rota passou a
/// evitar. Vazio quando os alertas não mudaram o caminho.
List<Ocorrencia> alertasEvitados(
  Viagem semAlertas,
  ResultadoViagem comAlertas,
  ImpactoAlertas impacto,
) {
  final usados = comAlertas is Viagem
      ? {
          for (final p in comAlertas.pernas)
            for (final e in p.etapas) e.trecho.id,
        }
      : const <String>{};
  final vistos = <String>{};
  return [
    for (final a in alertasNaViagem(semAlertas, impacto))
      if (!usados.contains(a.etapa.trecho.id) && vistos.add(a.ocorrencia.id))
        a.ocorrencia,
  ];
}

/// Agrupa alertas próximos para não encher o mapa de marcadores.
/// [raio] em unidades da planta (a tela converte conforme o zoom).
List<List<Ocorrencia>> agrupar(List<Ocorrencia> l, double raio) {
  final grupos = <List<Ocorrencia>>[];
  for (final o in l) {
    List<Ocorrencia>? alvo;
    for (final g in grupos) {
      if (_dist(g.first.x, g.first.y, o.x, o.y) <= raio) {
        alvo = g;
        break;
      }
    }
    if (alvo == null) {
      grupos.add([o]);
    } else {
      alvo.add(o);
    }
  }
  return grupos;
}
