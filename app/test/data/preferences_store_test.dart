// Testes de salvar e apagar preferências no aparelho (Etapa 2).

import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RF47: preferências salvas voltam ao reabrir o app', () async {
    final ctrl = await PreferencesController.restore(LocalPreferencesStore());
    ctrl.update((p) => p.copyWith(largeText: true, language: AppLanguage.es));
    await Future<void>.delayed(Duration.zero);

    final reaberto = await PreferencesController.restore(
      LocalPreferencesStore(),
    );
    expect(reaberto.prefs.largeText, isTrue);
    expect(reaberto.prefs.language, AppLanguage.es);
  });

  test('CA14: apagar remove o que foi salvo', () async {
    final store = LocalPreferencesStore();
    final ctrl = await PreferencesController.restore(store);
    ctrl.update((p) => p.copyWith(avoidStairs: true));
    await Future<void>.delayed(Duration.zero);
    await ctrl.eraseStored();

    final sp = await SharedPreferences.getInstance();
    expect(sp.getKeys().where((k) => k.startsWith('acessa.')), isEmpty);
    final reaberto = await PreferencesController.restore(store);
    expect(reaberto.prefs.activeCount, 0);
  });

  test('dado salvo corrompido volta ao padrão sem travar', () async {
    SharedPreferences.setMockInitialValues({
      'acessa.pref.largeText': 'talvez',
      'acessa.pref.language': 'klingon',
    });
    final ctrl = await PreferencesController.restore(LocalPreferencesStore());
    expect(ctrl.prefs.largeText, isFalse);
    expect(ctrl.prefs.language, AppLanguage.pt);
  });

  test('RNF13: só escolhas de recursos e idioma são salvas', () {
    expect(
      const Preferences().toMap().keys,
      unorderedEquals([
        'largeText',
        'highContrast',
        'audioGuidance',
        'textCommunication',
        'quickMessages',
        'avoidStairs',
        'preferElevators',
        'simplified',
        'calm',
        'language',
      ]),
    );
  });
}
