import 'package:flutter/widgets.dart';

import '../../features/welcome_preferences/preferences.dart';
import '../../features/welcome_preferences/preferences_scope.dart';
import 'textos_alertas.dart';
import 'textos_comunicacao.dart';
import 'textos_destino.dart';
import 'textos_inicio.dart';
import 'textos_navegacao.dart';

/// Tradução da interface (pt → en/es).
///
/// O português é a chave: o código continua legível e os testes seguem
/// encontrando os textos em português. Cada área tem seu próprio mapa
/// (`textos_*.dart`) para que equipes diferentes editem sem conflito.
///
/// Textos com partes variáveis usam modelos com `{nome}`:
///   'Faltam {m} m': ('{m} m to go', 'Faltan {m} m')
/// O valor capturado também é traduzido se houver tradução para ele
/// (ex.: "Térreo" → "Ground floor").
///
/// Nomes próprios de lojas e lugares não são traduzidos.
typedef Traducao = (String en, String es);

final Map<String, Traducao> _todos = {
  ...textosInicio,
  ...textosDestino,
  ...textosNavegacao,
  ...textosComunicacao,
  ...textosAlertas,
};

/// Idioma escolhido pelo visitante (atualiza a tela quando muda).
AppLanguage idiomaDe(BuildContext context) =>
    PreferencesScope.maybeOf(context)?.prefs.language ?? AppLanguage.pt;

/// Traduz [pt] para o idioma do visitante. Sem tradução, devolve [pt].
String tr(BuildContext context, String pt) => traduzir(pt, idiomaDe(context));

/// Versão sem contexto (para regras, anúncios e testes).
String traduzir(String pt, AppLanguage idioma) {
  if (idioma == AppLanguage.pt || pt.isEmpty) return pt;
  final exato = _todos[pt];
  if (exato != null) return _escolher(exato, idioma);
  for (final m in _modelos) {
    final r = m.aplicar(pt, idioma);
    if (r != null) return r;
  }
  return pt;
}

String _escolher(Traducao t, AppLanguage l) =>
    l == AppLanguage.es ? t.$2 : t.$1;

final List<_Modelo> _modelos = [
  for (final e in _todos.entries)
    if (e.key.contains('{')) _Modelo(e.key, e.value),
]..sort((a, b) => b.fixo.compareTo(a.fixo)); // mais específico primeiro

class _Modelo {
  _Modelo(this.chave, this.traducao)
    : fixo = chave.replaceAll(RegExp(r'\{\w+\}'), '').length {
    final nomes = <String>[];
    final padrao = chave.splitMapJoin(
      RegExp(r'\{(\w+)\}'),
      onMatch: (m) {
        nomes.add(m.group(1)!);
        return '(.+?)';
      },
      onNonMatch: RegExp.escape,
    );
    _re = RegExp('^$padrao\$', dotAll: true);
    _nomes = nomes;
  }

  final String chave;
  final Traducao traducao;
  final int fixo;
  late final RegExp _re;
  late final List<String> _nomes;

  String? aplicar(String texto, AppLanguage l) {
    final m = _re.firstMatch(texto);
    if (m == null) return null;
    var saida = _escolher(traducao, l);
    for (var i = 0; i < _nomes.length; i++) {
      final valor = m.group(i + 1)!;
      final traduzido = valor == texto ? valor : traduzir(valor, l);
      saida = saida.replaceAll('{${_nomes[i]}}', traduzido);
    }
    return saida;
  }
}

/// Atalho: `context.t('Começar')`.
extension TraduzirContexto on BuildContext {
  String t(String pt) => tr(this, pt);
}
