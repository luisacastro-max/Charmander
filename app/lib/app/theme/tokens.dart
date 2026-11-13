import 'package:flutter/material.dart';

/// Tokens visuais do Acessa+ — paleta "Noite neon" (escolhida na Etapa 1).
///
/// Todas as combinações de texto têm contraste mínimo de 4,5:1 (WCAG AA).
/// Valores medidos em docs/design/etapa-1-amostra-visual.md.
class AcessaColors {
  const AcessaColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.onPrimary,
    required this.marker,
    required this.onMarker,
    required this.communication,
    required this.navigation,
    required this.help,
    required this.onAccent,
    required this.border,
    required this.shadow,
    required this.focus,
    required this.simulation,
    required this.mapLine,
    required this.brightness,
  });

  final Color background; // fundo das telas
  final Color surface; // cartões neutros
  final Color ink; // texto principal
  final Color inkMuted; // texto secundário
  final Color primary; // ação principal
  final Color onPrimary;
  final Color marker; // marca-texto de destaque
  final Color onMarker;
  final Color communication; // pilar Comunicação Universal
  final Color navigation; // pilar Navegação Viva
  final Color help; // pilar Ajuda+
  final Color onAccent; // texto sobre as cores dos pilares
  final Color border; // contornos
  final Color shadow; // sombra deslocada do estilo "adesivo"
  final Color focus; // anel de foco do teclado
  final Color simulation; // avisos de simulação
  final Color mapLine; // linhas da planta no mapa vivo
  final Brightness brightness;

  /// Noite neon: azul-noite profundo com rosa, ciano e limão.
  static const standard = AcessaColors(
    background: Color(0xFF111A36),
    surface: Color(0xFF1B2547),
    ink: Color(0xFFF4F6FF),
    inkMuted: Color(0xFFB8C0E0),
    primary: Color(0xFFDFFF5E),
    onPrimary: Color(0xFF111A36),
    marker: Color(0xFFFF5C9D),
    onMarker: Color(0xFF111A36),
    communication: Color(0xFFFF5C9D),
    navigation: Color(0xFF3FE0E0),
    help: Color(0xFFDFFF5E),
    onAccent: Color(0xFF111A36),
    border: Color(0xFFF4F6FF),
    shadow: Color(0xFF05081A),
    focus: Color(0xFF3FE0E0),
    simulation: Color(0xFFFF9F43),
    mapLine: Color(0xFF3B4C86),
    brightness: Brightness.dark,
  );

  /// Redução de estímulos: mesma noite, cores dessaturadas.
  static const calm = AcessaColors(
    background: Color(0xFF171D30),
    surface: Color(0xFF212943),
    ink: Color(0xFFE4E7F2),
    inkMuted: Color(0xFFA9B0C8),
    primary: Color(0xFFCBD89C),
    onPrimary: Color(0xFF171D30),
    marker: Color(0xFFD99BB4),
    onMarker: Color(0xFF171D30),
    communication: Color(0xFFD99BB4),
    navigation: Color(0xFF9CCFCF),
    help: Color(0xFFCBD89C),
    onAccent: Color(0xFF171D30),
    border: Color(0xFFA9B0C8),
    shadow: Color(0xFF0B0F1C),
    focus: Color(0xFF9CCFCF),
    simulation: Color(0xFFD9A066),
    mapLine: Color(0xFF39425F),
    brightness: Brightness.dark,
  );

  /// Alto contraste: fundo preto, texto branco, destaques amarelos.
  static const highContrast = AcessaColors(
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFFFFFFFF),
    primary: Color(0xFFFFE600),
    onPrimary: Color(0xFF000000),
    marker: Color(0xFFFFE600),
    onMarker: Color(0xFF000000),
    communication: Color(0xFFFFE600),
    navigation: Color(0xFFFFE600),
    help: Color(0xFFFFE600),
    onAccent: Color(0xFF000000),
    border: Color(0xFFFFFFFF),
    shadow: Color(0xFFFFFFFF),
    focus: Color(0xFF00FFD0),
    simulation: Color(0xFFFFB000),
    mapLine: Color(0xFFFFFFFF),
    brightness: Brightness.dark,
  );
}

class AcessaSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// Alvo de toque mínimo (48 dp, recomendação Android/Material).
  static const minTouch = 48.0;

  /// Largura máxima do conteúdo ao rodar no navegador.
  static const maxContentWidth = 440.0;
}

class AcessaRadius {
  static const card = 20.0;
  static const button = 16.0;
  static const pill = 999.0;
}

/// Estilo "adesivo": borda forte + sombra deslocada sem desfoque.
/// Bordas nítidas ajudam pessoas com baixa visão a perceber limites.
class AcessaSticker {
  static const borderWidth = 2.0;
  static const shadowOffset = Offset(4, 4);
}
