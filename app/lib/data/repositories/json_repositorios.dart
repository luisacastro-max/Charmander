import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/comunicacao.dart';
import '../../domain/models/shopping.dart';
import 'repositorios.dart';

/// Lê e guarda em memória um arquivo JSON de assets/data.
class _JsonAsset {
  _JsonAsset(this.bundle, this.path);
  final AssetBundle bundle;
  final String path;
  Future<Map<String, dynamic>>? _cache;

  Future<Map<String, dynamic>> get data => _cache ??= bundle
      .loadString(path)
      .then((s) => jsonDecode(s) as Map<String, dynamic>);

  Future<List<T>> list<T>(String key, T Function(Map<String, dynamic>) f) async =>
      ((await data)[key] as List)
          .map((e) => f(e as Map<String, dynamic>))
          .toList(growable: false);
}

class JsonCatalogoRepository implements CatalogoRepository {
  JsonCatalogoRepository([AssetBundle? bundle])
    : _a = _JsonAsset(bundle ?? rootBundle, 'assets/data/catalogo.json');
  final _JsonAsset _a;

  @override
  Future<List<PontoReferencia>> pontos() =>
      _a.list('pontos', PontoReferencia.fromJson);

  @override
  Future<List<Local>> locais() => _a.list('locais', Local.fromJson);
}

class JsonPercursoRepository implements PercursoRepository {
  JsonPercursoRepository([AssetBundle? bundle])
    : _a = _JsonAsset(bundle ?? rootBundle, 'assets/data/percursos.json');
  final _JsonAsset _a;

  @override
  Future<List<Trecho>> trechos() => _a.list('trechos', Trecho.fromJson);
}

class JsonComunicacaoRepository implements ComunicacaoRepository {
  JsonComunicacaoRepository([AssetBundle? bundle])
    : _a = _JsonAsset(bundle ?? rootBundle, 'assets/data/comunicacao.json');
  final _JsonAsset _a;

  @override
  Future<List<CartaoComunicacao>> cartoes() =>
      _a.list('cartoes', CartaoComunicacao.fromJson);

  @override
  Future<List<CategoriaMensagens>> mensagensRapidas() =>
      _a.list('mensagensRapidas', CategoriaMensagens.fromJson);

  @override
  Future<List<FraseTraduzida>> frasesTraduzidas() =>
      _a.list('frasesTraduzidas', FraseTraduzida.fromJson);

  @override
  Future<List<SugestoesDoPonto>> sugestoesPorPonto() =>
      _a.list('sugestoesPorPonto', SugestoesDoPonto.fromJson);
}
