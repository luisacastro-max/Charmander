import 'package:flutter/foundation.dart';

import '../../features/welcome_preferences/preferences.dart';

/// Cartão de comunicação: símbolo + texto (RF27).
@immutable
class CartaoComunicacao {
  const CartaoComunicacao({
    required this.id,
    required this.icone,
    required this.texto,
  });

  final String id;
  final String icone;
  final String texto;

  factory CartaoComunicacao.fromJson(Map<String, dynamic> j) =>
      CartaoComunicacao(
        id: j['id'] as String,
        icone: j['icone'] as String,
        texto: j['texto'] as String,
      );
}

/// Grupo de mensagens rápidas por categoria (RF27).
@immutable
class CategoriaMensagens {
  const CategoriaMensagens({required this.categoria, required this.frases});

  final String categoria;
  final List<String> frases;

  factory CategoriaMensagens.fromJson(Map<String, dynamic> j) =>
      CategoriaMensagens(
        categoria: j['categoria'] as String,
        frases: (j['frases'] as List).cast<String>(),
      );
}

/// Frase essencial traduzida previamente — não é tradução automática (RF28).
@immutable
class FraseTraduzida {
  const FraseTraduzida({
    required this.id,
    required this.pt,
    required this.en,
    required this.es,
  });

  final String id;
  final String pt;
  final String en;
  final String es;

  String em(AppLanguage l) => switch (l) {
    AppLanguage.pt => pt,
    AppLanguage.en => en,
    AppLanguage.es => es,
  };

  factory FraseTraduzida.fromJson(Map<String, dynamic> j) => FraseTraduzida(
    id: j['id'] as String,
    pt: j['pt'] as String,
    en: j['en'] as String,
    es: j['es'] as String,
  );
}

/// Ação sugerida no card "Neste local" (RF50, RN14). Executa só por ação
/// do visitante: prepara uma [mensagem] ou ativa uma preferência.
@immutable
class AcaoSugerida {
  const AcaoSugerida({required this.titulo, this.mensagem, this.ativarPreferencia});

  final String titulo;
  final String? mensagem;
  final String? ativarPreferencia;

  factory AcaoSugerida.fromJson(Map<String, dynamic> j) => AcaoSugerida(
    titulo: j['titulo'] as String,
    mensagem: j['mensagem'] as String?,
    ativarPreferencia: j['ativarPreferencia'] as String?,
  );
}

@immutable
class SugestoesDoPonto {
  const SugestoesDoPonto({
    required this.pontoId,
    required this.titulo,
    required this.acoes,
  });

  final String pontoId;
  final String titulo;
  final List<AcaoSugerida> acoes;

  factory SugestoesDoPonto.fromJson(Map<String, dynamic> j) => SugestoesDoPonto(
    pontoId: j['pontoId'] as String,
    titulo: j['titulo'] as String,
    acoes: (j['acoes'] as List)
        .map((a) => AcaoSugerida.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}
