import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/welcome_preferences/preferences.dart';
import 'tokens.dart';

/// Disponibiliza as cores do Acessa+ via Theme.of(context).extension.
class AcessaTheme extends ThemeExtension<AcessaTheme> {
  const AcessaTheme(this.colors, {required this.highContrast});

  final AcessaColors colors;
  final bool highContrast;

  static AcessaTheme of(BuildContext context) =>
      Theme.of(context).extension<AcessaTheme>()!;

  @override
  AcessaTheme copyWith({AcessaColors? colors, bool? highContrast}) =>
      AcessaTheme(
        colors ?? this.colors,
        highContrast: highContrast ?? this.highContrast,
      );

  @override
  AcessaTheme lerp(AcessaTheme? other, double t) =>
      t < .5 ? this : (other ?? this);
}

AcessaColors colorsFor(Preferences p) {
  if (p.highContrast) return AcessaColors.highContrast;
  if (p.calm) return AcessaColors.calm;
  return AcessaColors.standard;
}

/// Tipografia:
/// - Títulos: Fredoka — arredondada e acolhedora (referência Pibaru).
/// - Texto: Atkinson Hyperlegible — criada pelo Braille Institute para
///   facilitar a leitura por pessoas com baixa visão (já usada no protótipo).
///
/// Etapa 1 carrega as fontes pelo pacote google_fonts. Para o app funcionar
/// offline (princípio "funciona no dispositivo"), as fontes serão
/// empacotadas em assets/ na Etapa 2.
/// Desligado nos testes automatizados, que não acessam a internet.
bool useBrandFonts = true;

ThemeData buildTheme(Preferences prefs) {
  final c = colorsFor(prefs);

  TextStyle display(double size, {FontWeight w = FontWeight.w700}) {
    final s = TextStyle(fontSize: size, fontWeight: w, height: 1.08);
    return useBrandFonts ? GoogleFonts.fredoka(textStyle: s) : s;
  }

  TextStyle body(double size, {FontWeight? w, double? height}) {
    final s = TextStyle(fontSize: size, fontWeight: w, height: height);
    return useBrandFonts ? GoogleFonts.atkinsonHyperlegible(textStyle: s) : s;
  }

  final TextTheme base = ThemeData.light().textTheme.apply(
    fontFamily: useBrandFonts
        ? GoogleFonts.atkinsonHyperlegible().fontFamily
        : null,
  );

  final text = base
      .copyWith(
        displayLarge: display(44),
        displayMedium: display(36),
        headlineMedium: display(28),
        titleLarge: display(22, w: FontWeight.w600),
        titleMedium: body(17, w: FontWeight.w700),
        bodyLarge: body(17, height: 1.45),
        bodyMedium: body(15, height: 1.45),
        labelLarge: body(17, w: FontWeight.w700),
      )
      .apply(bodyColor: c.ink, displayColor: c.ink);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.marker,
      onSecondary: c.onMarker,
      error: c.focus,
      onError: c.onPrimary,
      surface: c.surface,
      onSurface: c.ink,
    ),
    textTheme: text,
    focusColor: c.focus.withValues(alpha: .25),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [AcessaTheme(c, highContrast: prefs.highContrast)],
  );
}
