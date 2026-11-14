import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../app/i18n/i18n.dart';
import '../../features/welcome_preferences/preferences.dart';
import '../../features/welcome_preferences/preferences_scope.dart';

/// Voz do Acessa+ (texto para fala).
///
/// - Só fala quando o visitante liga "Orientações por áudio" (P11): é
///   uma escolha, não algo imposto.
/// - Fala no idioma escolhido, com o texto já traduzido.
/// - Funciona sem leitor de tela; quem usa TalkBack/VoiceOver continua
///   recebendo os anúncios normais do leitor.
/// - Uma fala nova interrompe a anterior, para não acumular instruções
///   atrasadas.
class Voz {
  Voz._();

  static final Voz instancia = Voz._();

  FlutterTts? _tts;
  AppLanguage? _idiomaAtual;
  bool _indisponivel = false;

  /// Últimas falas pedidas (para testes e depuração). Guarda até 20.
  @visibleForTesting
  static final List<String> historico = [];

  /// Fala [textoPt] traduzido, se o áudio estiver ligado nas preferências.
  Future<void> falar(BuildContext context, String textoPt) {
    final prefs = PreferencesScope.maybeOf(context)?.prefs;
    if (prefs == null || !prefs.audioGuidance) return Future.value();
    return falarNoIdioma(traduzir(textoPt, prefs.language), prefs.language);
  }

  /// Fala [texto] (já no idioma certo), independentemente da preferência.
  /// Use só para ação explícita do visitante, como um botão "Ouvir".
  Future<void> falarNoIdioma(String texto, AppLanguage idioma) async {
    if (texto.trim().isEmpty) return;
    historico.add(texto);
    if (historico.length > 20) historico.removeAt(0);
    if (_indisponivel) return;
    try {
      final tts = _tts ??= FlutterTts();
      if (_idiomaAtual != idioma) {
        await tts.setLanguage(_codigo(idioma));
        await tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
        _idiomaAtual = idioma;
      }
      await tts.stop();
      await tts.speak(texto);
    } catch (_) {
      // Sem motor de voz (testes, aparelho sem TTS): segue em silêncio.
      // O texto continua na tela e no leitor de tela.
      _indisponivel = true;
    }
  }

  Future<void> parar() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  static String _codigo(AppLanguage l) => switch (l) {
    AppLanguage.pt => 'pt-BR',
    AppLanguage.en => 'en-US',
    AppLanguage.es => 'es-ES',
  };
}

/// Avisa o visitante de um acontecimento: leitor de tela (sempre) e voz
/// (se "Orientações por áudio" estiver ligado). [textoPt] em português;
/// a tradução é feita aqui.
void anunciar(BuildContext context, String textoPt) {
  final idioma = idiomaDe(context);
  final texto = traduzir(textoPt, idioma);
  SemanticsService.sendAnnouncement(View.of(context), texto, TextDirection.ltr);
  Voz.instancia.falar(context, textoPt);
}
