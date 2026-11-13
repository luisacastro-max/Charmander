import 'package:flutter/widgets.dart';

import 'preferences.dart';

/// Controlador de preferências.
///
/// Etapa 1: só em memória. Etapa 2: persistência local (RF44, RF47, RNF11).
/// Usa apenas ChangeNotifier do Flutter para não antecipar a decisão
/// pendente sobre gerenciador de estado; migra fácil para Provider/Riverpod.
class PreferencesController extends ChangeNotifier {
  PreferencesController([Preferences initial = const Preferences()])
    : _prefs = initial;

  Preferences _prefs;
  Preferences get prefs => _prefs;

  void update(Preferences Function(Preferences) change) {
    final next = change(_prefs);
    if (identical(next, _prefs)) return;
    _prefs = next;
    notifyListeners();
  }

  void reset() {
    _prefs = const Preferences();
    notifyListeners();
  }
}

/// Disponibiliza o controlador para toda a árvore de widgets.
class PreferencesScope extends InheritedNotifier<PreferencesController> {
  const PreferencesScope({
    super.key,
    required PreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static PreferencesController of(BuildContext context) {
    final c = maybeOf(context);
    assert(c != null, 'PreferencesScope ausente na árvore.');
    return c!;
  }

  static PreferencesController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()?.notifier;
}
