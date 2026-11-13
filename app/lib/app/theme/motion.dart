import 'package:flutter/widgets.dart';

import '../../features/welcome_preferences/preferences_scope.dart';

/// Movimento do Acessa+.
///
/// Regra central: animação é um enfeite opcional, nunca a única forma de
/// transmitir informação. Ela é desligada quando:
/// - o sistema pede menos movimento (MediaQuery.disableAnimations), ou
/// - o visitante ativa "Redução de estímulos".
///
/// Princípio inspirado no gsap.matchMedia() + prefers-reduced-motion do
/// skill de GSAP, adaptado para Flutter.
class Motion {
  Motion._(this.enabled);

  final bool enabled;

  static Motion of(BuildContext context) {
    final systemReduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final calm = PreferencesScope.maybeOf(context)?.prefs.calm ?? false;
    return Motion._(!(systemReduce || calm));
  }

  // Durações curtas: rápidas o bastante para não atrasar ninguém.
  static const quick = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const stagger = Duration(milliseconds: 70);

  static const enter = Curves.easeOutCubic;
  static const pop = Curves.easeOutBack;

  Duration d(Duration value) => enabled ? value : Duration.zero;
}
