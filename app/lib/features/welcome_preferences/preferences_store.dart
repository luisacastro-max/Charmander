import 'package:shared_preferences/shared_preferences.dart';

import 'preferences.dart';

/// Onde as preferências ficam guardadas (RF44, RF47, RNF11).
abstract interface class PreferencesStore {
  Future<Preferences> load();
  Future<void> save(Preferences prefs);

  /// Apaga tudo o que foi guardado neste aparelho (RNF13, CA14).
  Future<void> clear();
}

/// Guarda no próprio aparelho com `shared_preferences`
/// (Android: SharedPreferences; iOS: NSUserDefaults; web: localStorage).
/// Nada é enviado para fora do dispositivo.
class LocalPreferencesStore implements PreferencesStore {
  static const _prefix = 'acessa.pref.';

  @override
  Future<Preferences> load() async {
    final sp = await SharedPreferences.getInstance();
    final map = <String, Object?>{
      for (final k in sp.getKeys().where((k) => k.startsWith(_prefix)))
        k.substring(_prefix.length): sp.get(k),
    };
    return Preferences.fromMap(map);
  }

  @override
  Future<void> save(Preferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    for (final e in prefs.toMap().entries) {
      final v = e.value;
      if (v is bool) {
        await sp.setBool('$_prefix${e.key}', v);
      } else {
        await sp.setString('$_prefix${e.key}', v.toString());
      }
    }
  }

  @override
  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    for (final k in sp.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await sp.remove(k);
    }
  }
}

/// Guarda só em memória (usado nos testes e como alternativa se o
/// armazenamento do aparelho falhar).
class MemoryPreferencesStore implements PreferencesStore {
  Preferences? _saved;

  @override
  Future<Preferences> load() async => _saved ?? const Preferences();

  @override
  Future<void> save(Preferences prefs) async => _saved = prefs;

  @override
  Future<void> clear() async => _saved = null;
}
