import 'package:flutter/widgets.dart';

import '../domain/models/comunicacao.dart';
import '../domain/models/shopping.dart';
import '../domain/rules/rotas.dart';
import 'repositories/json_repositorios.dart';
import 'repositories/repositorios.dart';

/// Dados do shopping demonstrativo já carregados, com o motor de rotas.
class ShoppingData {
  ShoppingData._(this.pontos, this.locais, this.trechos, this.sugestoes)
    : motor = MotorRotas(pontos, trechos),
      _porId = {for (final p in pontos) p.id: p};

  final List<PontoReferencia> pontos;
  final List<Local> locais;
  final List<Trecho> trechos;
  final List<SugestoesDoPonto> sugestoes;
  final MotorRotas motor;
  final Map<String, PontoReferencia> _porId;

  PontoReferencia ponto(String id) => _porId[id]!;

  /// Pisos na ordem do cadastro.
  List<String> get pisos {
    final r = <String>[];
    for (final p in pontos) {
      final piso = p.piso;
      if (piso != null && !r.contains(piso)) r.add(piso);
    }
    return r;
  }

  /// Pontos onde o visitante pode "estar" na simulação de beacon
  /// (corredores ficam de fora para a lista ser curta).
  List<PontoReferencia> get pontosSimulaveis =>
      pontos.where((p) => p.tipo != TipoPonto.corredor).toList();

  static Future<ShoppingData>? _cache;

  static Future<ShoppingData> carregar({
    CatalogoRepository? catalogo,
    PercursoRepository? percursos,
    ComunicacaoRepository? comunicacao,
  }) {
    if (catalogo == null && percursos == null && comunicacao == null) {
      return _cache ??= _carregar(
        JsonCatalogoRepository(),
        JsonPercursoRepository(),
        JsonComunicacaoRepository(),
      );
    }
    return _carregar(
      catalogo ?? JsonCatalogoRepository(),
      percursos ?? JsonPercursoRepository(),
      comunicacao ?? JsonComunicacaoRepository(),
    );
  }

  static Future<ShoppingData> _carregar(
    CatalogoRepository c,
    PercursoRepository p,
    ComunicacaoRepository m,
  ) async => ShoppingData._(
    await c.pontos(),
    await c.locais(),
    await p.trechos(),
    await m.sugestoesPorPonto(),
  );
}

/// Disponibiliza os dados já carregados para toda a árvore de widgets.
class DadosScope extends InheritedWidget {
  const DadosScope({super.key, required this.dados, required super.child});

  final ShoppingData dados;

  static ShoppingData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DadosScope>()?.dados;

  @override
  bool updateShouldNotify(DadosScope old) => old.dados != dados;
}
