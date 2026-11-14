import 'package:flutter/foundation.dart';

/// Tipo de problema que um visitante pode reportar no mapa colaborativo.
///
/// Os alertas são **relatos da comunidade**: ajudam a escolher o caminho,
/// mas não são verificação oficial do shopping nem garantia de segurança.
enum TipoOcorrencia {
  pisoMolhado,
  passagemInterditada,
  obstaculo,
  elevadorParado,
  escadaRolanteParada,
  rampaBloqueada,
  localCheio,
  outro,
}

/// O que um alerta faz com as rotas.
enum EfeitoOcorrencia {
  /// O trecho sai do cálculo (passagem interditada, elevador, rampa).
  bloqueia,

  /// O trecho fica mais "caro" e a rota avisa; usa alternativa se houver.
  aviso,
}

/// Situação de um alerta num dado momento.
enum SituacaoOcorrencia { ativa, resolvida, expirada }

extension DadosDoTipo on TipoOcorrencia {
  /// Nome curto em português (a tela traduz).
  String get rotulo => switch (this) {
    TipoOcorrencia.pisoMolhado => 'Piso molhado ou escorregadio',
    TipoOcorrencia.passagemInterditada => 'Passagem interditada',
    TipoOcorrencia.obstaculo => 'Obstáculo no caminho',
    TipoOcorrencia.elevadorParado => 'Elevador fora de serviço',
    TipoOcorrencia.escadaRolanteParada => 'Escada rolante parada',
    TipoOcorrencia.rampaBloqueada => 'Rampa bloqueada',
    TipoOcorrencia.localCheio => 'Local muito cheio',
    TipoOcorrencia.outro => 'Outro problema',
  };

  /// Por quanto tempo o alerta vale sem nova confirmação
  /// ("Ainda está aqui" renova o prazo).
  Duration get validade => switch (this) {
    TipoOcorrencia.pisoMolhado => const Duration(hours: 2),
    TipoOcorrencia.passagemInterditada => const Duration(hours: 8),
    TipoOcorrencia.obstaculo => const Duration(hours: 2),
    TipoOcorrencia.elevadorParado => const Duration(hours: 12),
    TipoOcorrencia.escadaRolanteParada => const Duration(hours: 12),
    TipoOcorrencia.rampaBloqueada => const Duration(hours: 6),
    TipoOcorrencia.localCheio => const Duration(hours: 1),
    TipoOcorrencia.outro => const Duration(hours: 3),
  };

  EfeitoOcorrencia get efeito => switch (this) {
    TipoOcorrencia.passagemInterditada ||
    TipoOcorrencia.elevadorParado ||
    TipoOcorrencia.rampaBloqueada => EfeitoOcorrencia.bloqueia,
    _ => EfeitoOcorrencia.aviso,
  };

  /// Quanto um alerta de aviso encarece o trecho (1 = não muda).
  /// Com multiplicador alto, a rota troca de caminho quando a alternativa
  /// não é muito mais longa; senão segue pelo trecho, com aviso.
  double get penalidade => switch (this) {
    TipoOcorrencia.pisoMolhado => 4,
    TipoOcorrencia.obstaculo => 4,
    TipoOcorrencia.escadaRolanteParada => 3,
    TipoOcorrencia.localCheio => 2.5,
    TipoOcorrencia.outro => 2,
    _ => 1,
  };
}

TipoOcorrencia tipoOcorrenciaDe(Object? raw) {
  for (final t in TipoOcorrencia.values) {
    if (t.name == raw) return t;
  }
  throw FormatException('Tipo de ocorrência inválido: $raw');
}

/// Dados de um novo relato, antes de ir para o servidor.
@immutable
class NovaOcorrencia {
  const NovaOcorrencia({
    required this.shoppingId,
    required this.tipo,
    required this.piso,
    required this.x,
    required this.y,
    this.pontoId,
    this.descricao,
  });

  final String shoppingId;
  final TipoOcorrencia tipo;
  final String piso;

  /// Posição na planta (mesmas unidades de `PontoReferencia.x/y`).
  final double x;
  final double y;

  /// Ponto de referência mais próximo, para descrever o local em texto.
  final String? pontoId;

  /// Descrição opcional (até [maxDescricao] caracteres). Não deve conter
  /// dados pessoais; a tela avisa isso.
  final String? descricao;

  static const maxDescricao = 140;

  Map<String, dynamic> toJson() => {
    'shoppingId': shoppingId,
    'tipo': tipo.name,
    'piso': piso,
    'x': x,
    'y': y,
    if (pontoId != null) 'pontoId': pontoId,
    if (descricao != null && descricao!.trim().isNotEmpty)
      'descricao': descricao!.trim(),
  };
}

/// Alerta da comunidade já registrado (vem do servidor).
///
/// O servidor guarda quem confirmou/resolveu só para não contar duas vezes
/// a mesma sessão anônima; o app recebe apenas as contagens.
@immutable
class Ocorrencia {
  const Ocorrencia({
    required this.id,
    required this.shoppingId,
    required this.tipo,
    required this.piso,
    required this.x,
    required this.y,
    required this.criadaEm,
    required this.confirmadaEm,
    this.pontoId,
    this.descricao,
    this.confirmacoes = 1,
    this.resolucoes = 0,
    this.resolvidaEm,
  });

  final String id;
  final String shoppingId;
  final TipoOcorrencia tipo;
  final String piso;
  final double x;
  final double y;
  final String? pontoId;
  final String? descricao;
  final DateTime criadaEm;

  /// Última vez que alguém disse "Ainda está aqui" (ou a criação).
  final DateTime confirmadaEm;

  /// Pessoas (sessões) que relataram ou confirmaram. Começa em 1.
  final int confirmacoes;

  /// Pessoas que disseram "Já foi resolvido" desde a última confirmação.
  final int resolucoes;

  /// Quando o alerta foi dado como resolvido (ver regra em ocorrencias.dart).
  final DateTime? resolvidaEm;

  Ocorrencia copyWith({
    DateTime? confirmadaEm,
    int? confirmacoes,
    int? resolucoes,
    DateTime? resolvidaEm,
    bool limparResolvida = false,
  }) => Ocorrencia(
    id: id,
    shoppingId: shoppingId,
    tipo: tipo,
    piso: piso,
    x: x,
    y: y,
    pontoId: pontoId,
    descricao: descricao,
    criadaEm: criadaEm,
    confirmadaEm: confirmadaEm ?? this.confirmadaEm,
    confirmacoes: confirmacoes ?? this.confirmacoes,
    resolucoes: resolucoes ?? this.resolucoes,
    resolvidaEm: limparResolvida ? null : (resolvidaEm ?? this.resolvidaEm),
  );

  factory Ocorrencia.fromJson(Map<String, dynamic> j) => Ocorrencia(
    id: j['id'] as String,
    shoppingId: j['shoppingId'] as String,
    tipo: tipoOcorrenciaDe(j['tipo']),
    piso: j['piso'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    pontoId: j['pontoId'] as String?,
    descricao: j['descricao'] as String?,
    criadaEm: DateTime.parse(j['criadaEm'] as String),
    confirmadaEm: DateTime.parse(j['confirmadaEm'] as String),
    confirmacoes: (j['confirmacoes'] as num?)?.toInt() ?? 1,
    resolucoes: (j['resolucoes'] as num?)?.toInt() ?? 0,
    resolvidaEm: j['resolvidaEm'] == null
        ? null
        : DateTime.parse(j['resolvidaEm'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shoppingId': shoppingId,
    'tipo': tipo.name,
    'piso': piso,
    'x': x,
    'y': y,
    if (pontoId != null) 'pontoId': pontoId,
    if (descricao != null) 'descricao': descricao,
    'criadaEm': criadaEm.toUtc().toIso8601String(),
    'confirmadaEm': confirmadaEm.toUtc().toIso8601String(),
    'confirmacoes': confirmacoes,
    'resolucoes': resolucoes,
    if (resolvidaEm != null)
      'resolvidaEm': resolvidaEm!.toUtc().toIso8601String(),
  };
}
