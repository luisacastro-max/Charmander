import 'package:flutter/widgets.dart';

import 'preferences.dart';
import 'preferences_store.dart';

/// Controlador de preferências.
///
/// Toda mudança é salva no aparelho (RF44, RF47, RNF11). Usa só
/// ChangeNotifier do Flutter (decisão da Etapa 2); migra fácil para
/// Provider/Riverpod se a equipe preferir.
class PreferencesController extends ChangeNotifier {
  PreferencesController([
    Preferences initial = const Preferences(),
    PreferencesStore? store,
  ]) : _prefs = initial,
       _store = store ?? MemoryPreferencesStore();

  /// Cria o controlador já com as preferências salvas no aparelho.
  /// Se a leitura falhar, começa com o padrão — o app nunca trava por isso.
  static Future<PreferencesController> restore(PreferencesStore store) async {
    try {
      return PreferencesController(await store.load(), store);
    } catch (_) {
      return PreferencesController(const Preferences(), store);
    }
  }

  final PreferencesStore _store;
  Preferences _prefs;
  Preferences get prefs => _prefs;

  void update(Preferences Function(Preferences) change) {
    final next = change(_prefs);
    if (identical(next, _prefs)) return;
    _prefs = next;
    notifyListeners();
    _store.save(next).ignore();
  }

  /// Apaga as preferências salvas neste aparelho e volta ao padrão
  /// (RNF13, CA14).
  Future<void> eraseStored() async {
    _prefs = const Preferences();
    notifyListeners();
    await _store.clear();
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
