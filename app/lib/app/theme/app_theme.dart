import 'package:flutter/material.dart';

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
/// Desde a Etapa 2 as fontes ficam empacotadas no app (assets/fonts),
/// sem depender de internet. Licença: SIL Open Font License 1.1.
const fontDisplay = 'Fredoka';
const fontBody = 'AtkinsonHyperlegible';

ThemeData buildTheme(Preferences prefs) {
  final c = colorsFor(prefs);

  // Fredoka é uma fonte variável: o peso vem do eixo "wght".
  TextStyle display(double size, {FontWeight w = FontWeight.w700}) =>
      TextStyle(
        fontFamily: fontDisplay,
        fontSize: size,
        fontWeight: w,
        fontVariations: [FontVariation.weight(w.value.toDouble())],
        height: 1.08,
      );

  TextStyle body(double size, {FontWeight? w, double? height}) => TextStyle(
    fontFamily: fontBody,
    fontSize: size,
    fontWeight: w,
    height: height,
  );

  final TextTheme base = ThemeData.light().textTheme.apply(
    fontFamily: fontBody,
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
