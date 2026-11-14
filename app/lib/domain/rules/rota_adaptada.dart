import 'package:flutter/foundation.dart';

import '../models/shopping.dart';
import 'rotas.dart';
import 'viagem.dart';

/// Comparação entre a rota "mais usada" (sem preferências pessoais) e a
/// rota adaptada às preferências do visitante. Mostra que o caminho muda
/// conforme a acessibilidade: ex.: quem não usa escadas "dá a volta" pelo
/// elevador em vez de subir pela escada rolante.
///
/// Os dados são estruturados (etapas, metros, minutos); a UI monta e
/// traduz os textos.
mixin _Diferenca {
  List<EtapaRota> get _etapasPrincipal;
  List<EtapaRota> get _etapasAdaptada;
  int get _distanciaPrincipal;
  int get _distanciaAdaptada;
  int get _minutosPrincipal;
  int get _minutosAdaptada;

  /// A rota adaptada é diferente da mais usada (outros trechos).
  bool get mudou => !listEquals(
    [for (final e in _etapasPrincipal) e.trecho.id],
    [for (final e in _etapasAdaptada) e.trecho.id],
  );

  /// Etapas da rota mais usada com escada ou escada rolante que a rota
  /// adaptada não usa. Só a troca de piso (ou degraus avulsos) conta: os
  /// trechos de aproximação, marcados com escada pela regra conservadora,
  /// não aparecem de novo.
  List<EtapaRota> get obstaculosEvitados {
    final usados = {for (final e in _etapasAdaptada) e.trecho.id};
    return [
      for (final e in _etapasPrincipal)
        if (!usados.contains(e.trecho.id) && ehObstaculo(e)) e,
    ];
  }

  /// Etapas da rota adaptada com elevador ou rampa que a mais usada não usa.
  List<EtapaRota> get substitutos {
    final usados = {for (final e in _etapasPrincipal) e.trecho.id};
    return [
      for (final e in _etapasAdaptada)
        if (!usados.contains(e.trecho.id) &&
            (e.trecho.trocaPiso == TrocaPiso.elevador ||
                e.trecho.trocaPiso == TrocaPiso.rampa))
          e,
    ];
  }

  /// O que a rota adaptada evita, em português e sem repetir
  /// (ex.: ["escada rolante"]). A tela traduz cada item.
  List<String> get nomesEvitados =>
      _semRepetir([for (final e in obstaculosEvitados) nomeDaBarreira(e)]);

  /// O que a rota adaptada usa no lugar (ex.: ["elevador"]).
  List<String> get nomesSubstitutos => _semRepetir([
    for (final e in substitutos) nomeDaTroca(e.trecho.trocaPiso!),
  ]);

  /// Metros a mais da rota adaptada (0 quando não mudou).
  int get extraM => _distanciaAdaptada - _distanciaPrincipal;

  /// Minutos a mais da rota adaptada, pela estimativa de cada rota.
  int get extraMin => _minutosAdaptada - _minutosPrincipal;
}

/// Etapa que é barreira para quem não usa escadas: troca de piso por
/// escada/escada rolante, ou degraus num trecho que não é só a aproximação
/// de uma escada.
bool ehObstaculo(EtapaRota e) {
  final t = e.trecho;
  if (t.trocaPiso == TrocaPiso.escada ||
      t.trocaPiso == TrocaPiso.escadaRolante) {
    return true;
  }
  return t.trocaPiso == null &&
      t.escada &&
      e.de.tipo != TipoPonto.escada &&
      e.para.tipo != TipoPonto.escada;
}

/// Nome curto (pt) de uma barreira: a troca de piso por escada ou escada
/// rolante, ou "degraus" num trecho com escada.
String nomeDaBarreira(EtapaRota e) => switch (e.trecho.trocaPiso) {
  TrocaPiso.escadaRolante => 'escada rolante',
  TrocaPiso.escada => 'escada',
  _ => 'degraus',
};

/// Nome curto (pt) de um meio de troca de piso.
String nomeDaTroca(TrocaPiso t) => switch (t) {
  TrocaPiso.elevador => 'elevador',
  TrocaPiso.rampa => 'rampa',
  TrocaPiso.escada => 'escada',
  TrocaPiso.escadaRolante => 'escada rolante',
};

/// Como a viagem troca de piso, na ordem e sem repetir
/// (ex.: ["escada rolante"]). Vazio quando fica num piso só.
List<String> meiosDeTrocaDePiso(Viagem v) => _semRepetir([
  for (final p in v.pernas)
    for (final e in p.etapas)
      if (e.trecho.trocaPiso case final t?) nomeDaTroca(t),
]);

List<String> _semRepetir(List<String> l) => [
  ...{...l},
];

/// Resultado de [RotaAdaptadaNoMotor.compararRota].
sealed class ResultadoComparacao {
  const ResultadoComparacao();
}

/// As duas rotas existem.
@immutable
class ComparacaoRota extends ResultadoComparacao with _Diferenca {
  const ComparacaoRota({required this.principal, required this.adaptada});

  /// Rota mais usada: [CriteriosRota.semPreferencias].
  final Rota principal;

  /// Rota com as preferências do visitante.
  final Rota adaptada;

  @override
  List<EtapaRota> get _etapasPrincipal => principal.etapas;
  @override
  List<EtapaRota> get _etapasAdaptada => adaptada.etapas;
  @override
  int get _distanciaPrincipal => principal.distanciaM;
  @override
  int get _distanciaAdaptada => adaptada.distanciaM;
  @override
  int get _minutosPrincipal => principal.minutos;
  @override
  int get _minutosAdaptada => adaptada.minutos;
}

/// Não há rota adaptada (RN04). [principal] pode existir ou não.
@immutable
class RotaAdaptadaImpossivel extends ResultadoComparacao {
  const RotaAdaptadaImpossivel({required this.principal, required this.motivo});

  final ResultadoRota principal;
  final SemRota motivo;
}

/// Resultado de [RotaAdaptadaNoMotor.compararViagem].
sealed class ResultadoComparacaoViagem {
  const ResultadoComparacaoViagem();
}

/// As duas viagens existem; compara perna a perna e no total.
@immutable
class ComparacaoViagem extends ResultadoComparacaoViagem with _Diferenca {
  const ComparacaoViagem({required this.principal, required this.adaptada});

  final Viagem principal;
  final Viagem adaptada;

  /// Comparação de cada perna (mesmas paradas nas duas viagens).
  List<ComparacaoRota> get pernas => [
    for (var i = 0; i < adaptada.pernas.length; i++)
      ComparacaoRota(
        principal: principal.pernas[i],
        adaptada: adaptada.pernas[i],
      ),
  ];

  @override
  List<EtapaRota> get _etapasPrincipal => [
    for (final p in principal.pernas) ...p.etapas,
  ];
  @override
  List<EtapaRota> get _etapasAdaptada => [
    for (final p in adaptada.pernas) ...p.etapas,
  ];
  @override
  int get _distanciaPrincipal => principal.distanciaM;
  @override
  int get _distanciaAdaptada => adaptada.distanciaM;
  @override
  int get _minutosPrincipal => principal.minutos;
  @override
  int get _minutosAdaptada => adaptada.minutos;
}

/// Alguma perna não tem rota adaptada (RN04).
@immutable
class ViagemAdaptadaImpossivel extends ResultadoComparacaoViagem {
  const ViagemAdaptadaImpossivel({
    required this.principal,
    required this.motivo,
  });

  final ResultadoViagem principal;
  final ViagemImpossivel motivo;
}

extension RotaAdaptadaNoMotor on MotorRotas {
  /// Compara a rota mais usada com a rota adaptada aos critérios [c].
  /// Sem preferências pessoais, as duas são iguais e `mudou` é falso.
  ResultadoComparacao compararRota(
    String origem,
    String destino,
    CriteriosRota c,
  ) {
    final principal = calcular(origem, destino, c.semPreferencias);
    final adaptada = calcular(origem, destino, c);
    return switch ((principal, adaptada)) {
      (Rota p, Rota a) => ComparacaoRota(principal: p, adaptada: a),
      (_, SemRota a) => RotaAdaptadaImpossivel(principal: principal, motivo: a),
      // Sem rota mesmo sem preferências, mas com elas há: não acontece
      // (preferências só removem ou encarecem trechos).
      (SemRota p, Rota _) => RotaAdaptadaImpossivel(
        principal: principal,
        motivo: p,
      ),
    };
  }

  /// Igual a [compararRota], para uma viagem com paradas.
  ResultadoComparacaoViagem compararViagem(
    String origem,
    List<String> paradas,
    CriteriosRota c,
  ) {
    final principal = calcularViagem(origem, paradas, c.semPreferencias);
    final adaptada = calcularViagem(origem, paradas, c);
    return switch ((principal, adaptada)) {
      (Viagem p, Viagem a) => ComparacaoViagem(principal: p, adaptada: a),
      (_, ViagemImpossivel a) => ViagemAdaptadaImpossivel(
        principal: principal,
        motivo: a,
      ),
      (ViagemImpossivel p, Viagem _) => ViagemAdaptadaImpossivel(
        principal: principal,
        motivo: p,
      ),
    };
  }
}
