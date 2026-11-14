import 'package:flutter/foundation.dart';

/// Tipo de ponto de referência no mapa.
enum TipoPonto {
  entrada,
  servico,
  loja,
  alimentacao,
  escada,
  elevador,
  corredor,
}

/// Como um trecho troca de piso, quando troca.
enum TrocaPiso { elevador, rampa, escada, escadaRolante }

/// Nível de movimento de pessoas cadastrado para o trecho (RN10: não é
/// medição em tempo real).
enum Movimento { normal, alto }

T _enum<T extends Enum>(List<T> values, Object? raw, String campo) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  throw FormatException('Valor inválido para "$campo": $raw');
}

/// Ponto de referência associado a um beacon BLE simulado (RN09).
@immutable
class PontoReferencia {
  const PontoReferencia({
    required this.id,
    required this.nome,
    required this.piso,
    required this.beacon,
    required this.x,
    required this.y,
    required this.tipo,
    required this.saidaEmergencia,
  });

  final String id;
  final String nome;
  final String? piso;
  final String beacon;
  final double x;
  final double y;
  final TipoPonto tipo;
  final bool saidaEmergencia;

  factory PontoReferencia.fromJson(Map<String, dynamic> j) => PontoReferencia(
    id: j['id'] as String,
    nome: j['nome'] as String,
    piso: j['piso'] as String?,
    beacon: j['beacon'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    tipo: _enum(TipoPonto.values, j['tipo'], 'tipo'),
    saidaEmergencia: j['saidaEmergencia'] as bool? ?? false,
  );
}

/// Estabelecimento ou serviço do shopping demonstrativo (RF07–RF10).
@immutable
class Local {
  const Local({
    required this.id,
    required this.pontoId,
    required this.nome,
    required this.categoria,
    required this.icone,
    this.descricao,
    this.recursos,
    this.horario,
    this.destino = true,
    this.acessivel = false,
    this.palavrasChave = const [],
  });

  final String id;
  final String pontoId;
  final String nome;
  final String categoria;
  final String icone;
  final String? descricao;

  /// `null` = não cadastrado (exibir "Não informado", RN06).
  final List<String>? recursos;
  final String? horario;

  /// Se pode ser escolhido como destino de rota (a escada não pode).
  final bool destino;

  /// Marcado como acessível no cadastro (ex.: banheiro PNE).
  final bool acessivel;

  /// Termos extras para a busca (ex.: "wc", "fraldário").
  final List<String> palavrasChave;

  /// Busca por nome, categoria, recursos e palavras-chave, sem acentos.
  bool corresponde(String consulta) {
    final q = semAcento(consulta.trim().toLowerCase());
    if (q.isEmpty) return true;
    final alvo = semAcento(
      [nome, categoria, ...?recursos, ...palavrasChave].join(' ').toLowerCase(),
    );
    return q.split(RegExp(r'\s+')).every(alvo.contains);
  }

  factory Local.fromJson(Map<String, dynamic> j) => Local(
    id: j['id'] as String,
    pontoId: j['pontoId'] as String,
    nome: j['nome'] as String,
    categoria: j['categoria'] as String,
    icone: j['icone'] as String,
    descricao: j['descricao'] as String?,
    recursos: (j['recursos'] as List?)?.cast<String>(),
    horario: j['horario'] as String?,
    destino: j['destino'] as bool? ?? true,
    acessivel: j['acessivel'] as bool? ?? false,
    palavrasChave: (j['palavrasChave'] as List?)?.cast<String>() ?? const [],
  );
}

/// Remove acentos para a busca ("sanitário" encontra "sanitario").
String semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i < 0 ? ch : para[i]);
  }
  return b.toString();
}

/// Ligação entre dois pontos de referência (sem direção).
@immutable
class Trecho {
  const Trecho({
    required this.id,
    required this.de,
    required this.para,
    required this.distanciaM,
    required this.escada,
    required this.trocaPiso,
    required this.movimento,
  });

  final String id;
  final String de;
  final String para;
  final int distanciaM;

  /// Tem degraus. Rotas "sem escadas" nunca usam este trecho (RN03).
  final bool escada;
  final TrocaPiso? trocaPiso;
  final Movimento movimento;

  bool liga(String a, String b) =>
      (de == a && para == b) || (de == b && para == a);

  factory Trecho.fromJson(Map<String, dynamic> j) => Trecho(
    id: j['id'] as String,
    de: j['de'] as String,
    para: j['para'] as String,
    distanciaM: j['distanciaM'] as int,
    escada: j['escada'] as bool,
    trocaPiso: j['trocaPiso'] == null
        ? null
        : _enum(TrocaPiso.values, j['trocaPiso'], 'trocaPiso'),
    movimento: _enum(Movimento.values, j['movimento'], 'movimento'),
  );
}
