import 'package:flutter/foundation.dart';

/// Idiomas previstos no MVP (decisão pendente "d"/"e": por ora só afetam
/// frases e voz; a interface segue em português).
enum AppLanguage { pt, en, es }

/// Preferências do visitante. Não descrevem deficiência nem diagnóstico (RN01):
/// cada campo é um recurso que a pessoa escolhe.
///
/// Comunicação e mobilidade são independentes (RN02, RNF06): mudar uma
/// nunca altera a outra.
@immutable
class Preferences {
  const Preferences({
    this.largeText = false,
    this.highContrast = false,
    this.audioGuidance = false,
    this.textCommunication = false,
    this.quickMessages = false,
    this.avoidStairs = false,
    this.preferElevators = false,
    this.simplified = false,
    this.calm = false,
    this.language = AppLanguage.pt,
  });

  // Visão
  final bool largeText;
  final bool highContrast;
  final bool audioGuidance;
  // Audição e comunicação
  final bool textCommunication;
  final bool quickMessages;
  // Mobilidade
  final bool avoidStairs;
  final bool preferElevators;
  // Sensorial e compreensão
  final bool simplified;
  final bool calm;

  final AppLanguage language;

  Preferences copyWith({
    bool? largeText,
    bool? highContrast,
    bool? audioGuidance,
    bool? textCommunication,
    bool? quickMessages,
    bool? avoidStairs,
    bool? preferElevators,
    bool? simplified,
    bool? calm,
    AppLanguage? language,
  }) {
    return Preferences(
      largeText: largeText ?? this.largeText,
      highContrast: highContrast ?? this.highContrast,
      audioGuidance: audioGuidance ?? this.audioGuidance,
      textCommunication: textCommunication ?? this.textCommunication,
      quickMessages: quickMessages ?? this.quickMessages,
      avoidStairs: avoidStairs ?? this.avoidStairs,
      preferElevators: preferElevators ?? this.preferElevators,
      simplified: simplified ?? this.simplified,
      calm: calm ?? this.calm,
      language: language ?? this.language,
    );
  }

  int get activeCount => [
    largeText,
    highContrast,
    audioGuidance,
    textCommunication,
    quickMessages,
    avoidStairs,
    preferElevators,
    simplified,
    calm,
  ].where((v) => v).length;
}
