import 'package:flutter/foundation.dart';

import '../models/shopping.dart';

/// Critérios do percurso, vindos das preferências do visitante.
@immutable
class CriteriosRota {
  const CriteriosRota({
    this.semEscadas = false,
    this.preferirElevador = false,
    this.caminhoTranquilo = false,
  });

  /// RN03: nenhum trecho com escada (inclui escada rolante).
  final bool semEscadas;

  /// Troca de piso por elevador fica bem mais "barata" que por escada.
  final bool preferirElevador;

  /// Evita trechos cadastrados com muito movimento (RN10).
  final bool caminhoTranquilo;
}

/// Uma etapa do percurso, com instrução em texto (RF18).
@immutable
class EtapaRota {
  const EtapaRota({
    required this.de,
    required this.para,
    required this.trecho,
    required this.instrucao,
  });

  final PontoReferencia de;
  final PontoReferencia para;
  final Trecho trecho;
  final String instrucao;
}

/// Resultado do cálculo: uma rota ou o motivo de não haver rota.
sealed class ResultadoRota {
  const ResultadoRota();
}

@immutable
class Rota extends ResultadoRota {
  const Rota({
    required this.pontos,
    required this.etapas,
    required this.criterios,
  });

  final List<PontoReferencia> pontos;
  final List<EtapaRota> etapas;
  final CriteriosRota criterios;

  int get distanciaM => etapas.fold(0, (s, e) => s + e.trecho.distanciaM);

  /// Estimativa a passo calmo (~50 m/min), mínimo 1 minuto.
  int get minutos => (distanciaM / 50).ceil().clamp(1, 999);

  bool get usaEscada => etapas.any((e) => e.trecho.escada);
  bool get usaElevador =>
      etapas.any((e) => e.trecho.trocaPiso == TrocaPiso.elevador);

  /// Pisos na ordem em que aparecem no caminho.
  List<String> get pisos {
    final r = <String>[];
    for (final p in pontos) {
      final piso = p.piso ?? 'Não informado';
      if (r.isEmpty || r.last != piso) r.add(piso);
    }
    return r;
  }
}

/// RN04: não existe percurso compatível. O app informa a limitação e
/// oferece alternativas, sem tirar restrições por conta própria.
@immutable
class SemRota extends ResultadoRota {
  const SemRota({required this.motivo, this.existeComEscada = false});

  final String motivo;

  /// Existe caminho se o visitante decidir aceitar escadas. O app só
  /// informa — a decisão de mudar a preferência é sempre do visitante.
  final bool existeComEscada;
}

/// Calcula rotas sobre pontos e trechos cadastrados (decisão: opção B da
/// arquitetura). O resultado vem só dos dados cadastrados (RN06).
class MotorRotas {
  MotorRotas(List<PontoReferencia> pontos, this.trechos)
    : _pontos = {for (final p in pontos) p.id: p};

  final Map<String, PontoReferencia> _pontos;
  final List<Trecho> trechos;

  PontoReferencia ponto(String id) => _pontos[id]!;

  ResultadoRota calcular(String origem, String destino, CriteriosRota c) {
    if (origem == destino) {
      return Rota(pontos: [ponto(origem)], etapas: const [], criterios: c);
    }
    final caminho = _dijkstra(origem, destino, c);
    if (caminho != null) return _montar(origem, caminho, c);

    final comEscada = c.semEscadas
        ? _dijkstra(
                origem,
                destino,
                CriteriosRota(
                  preferirElevador: c.preferirElevador,
                  caminhoTranquilo: c.caminhoTranquilo,
                ),
              ) !=
              null
        : false;
    return SemRota(
      motivo: comEscada
          ? 'Não há caminho sem escadas até ${ponto(destino).nome}.'
          : 'Não encontramos caminho cadastrado até ${ponto(destino).nome}.',
      existeComEscada: comEscada,
    );
  }

  double _custo(Trecho t, CriteriosRota c) {
    var d = t.distanciaM.toDouble();
    if (c.preferirElevador &&
        (t.trocaPiso == TrocaPiso.escada ||
            t.trocaPiso == TrocaPiso.escadaRolante)) {
      d *= 6;
    }
    if (c.caminhoTranquilo && t.movimento == Movimento.alto) d *= 3;
    return d;
  }

  List<Trecho>? _dijkstra(String origem, String destino, CriteriosRota c) {
    final permitidos = trechos.where((t) => !(c.semEscadas && t.escada));
    final viz = <String, List<Trecho>>{};
    for (final t in permitidos) {
      (viz[t.de] ??= []).add(t);
      (viz[t.para] ??= []).add(t);
    }
    final dist = <String, double>{origem: 0};
    final anterior = <String, Trecho>{};
    final abertos = {origem};
    final fechados = <String>{};
    while (abertos.isNotEmpty) {
      final u = abertos.reduce((a, b) => dist[a]! <= dist[b]! ? a : b);
      abertos.remove(u);
      if (u == destino) break;
      fechados.add(u);
      for (final t in viz[u] ?? const <Trecho>[]) {
        final v = t.de == u ? t.para : t.de;
        if (fechados.contains(v)) continue;
        final nd = dist[u]! + _custo(t, c);
        if (dist[v] == null || nd < dist[v]!) {
          dist[v] = nd;
          anterior[v] = t;
          abertos.add(v);
        }
      }
    }
    if (!anterior.containsKey(destino)) return null;
    final caminho = <Trecho>[];
    var atual = destino;
    while (atual != origem) {
      final t = anterior[atual]!;
      caminho.insert(0, t);
      atual = t.de == atual ? t.para : t.de;
    }
    return caminho;
  }

  Rota _montar(String origem, List<Trecho> caminho, CriteriosRota c) {
    final pts = <PontoReferencia>[ponto(origem)];
    final etapas = <EtapaRota>[];
    var atual = origem;
    for (final t in caminho) {
      final prox = t.de == atual ? t.para : t.de;
      final de = ponto(atual), para = ponto(prox);
      etapas.add(
        EtapaRota(
          de: de,
          para: para,
          trecho: t,
          instrucao: instrucao(de, para, t),
        ),
      );
      pts.add(para);
      atual = prox;
    }
    return Rota(pontos: pts, etapas: etapas, criterios: c);
  }

  /// Instrução curta e direta em português (RNF03).
  static String instrucao(PontoReferencia de, PontoReferencia para, Trecho t) {
    switch (t.trocaPiso) {
      case TrocaPiso.elevador:
        return 'Pegue o elevador até o ${para.piso ?? 'próximo piso'}.';
      case TrocaPiso.escadaRolante:
        return 'Suba pela escada rolante até o ${para.piso ?? 'próximo piso'}.';
      case TrocaPiso.escada:
        return 'Use a escada até o ${para.piso ?? 'próximo piso'}. '
            'Atenção: trecho com degraus.';
      case TrocaPiso.rampa:
        return 'Siga pela rampa até o ${para.piso ?? 'próximo piso'}.';
      case null:
        final alvo = para.tipo == TipoPonto.corredor
            ? 'o ${para.nome}'
            : para.nome;
        var s = 'Siga ${t.distanciaM} metros até $alvo.';
        if (t.escada) s += ' Atenção: trecho com degraus.';
        if (t.movimento == Movimento.alto) {
          s += ' Trecho com mais movimento de pessoas.';
        }
        return s;
    }
  }
}
