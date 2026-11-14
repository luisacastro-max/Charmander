// Idioma, voz e mensagens rápidas nas telas de destino e rota.

import 'package:acessa_plus/app/i18n/i18n.dart';
import 'package:acessa_plus/core/voz/voz.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'destino_test.dart' as d;

/// Abre "Para onde?" em português (as telas iniciais têm a própria
/// tradução) e então troca as preferências, como o visitante faria.
Future<PreferencesController> abrirCom(
  WidgetTester t,
  Preferences prefs,
) async {
  final ctrl = await d.abrirDestino(t);
  ctrl.update((_) => prefs);
  await t.pumpAndSettle();
  return ctrl;
}

void main() {
  test('Modelos traduzem as partes variáveis', () {
    expect(traduzir('Piso: 2º piso', AppLanguage.en), 'Floor: 2nd floor');
    expect(traduzir('Piso: Todos', AppLanguage.es), 'Piso: Todos');
    expect(traduzir('12 resultados', AppLanguage.en), '12 results');
    expect(
      traduzir(
        'Não há caminho sem escadas até Galeria do Mezanino.',
        AppLanguage.en,
      ),
      'There is no step-free path to Galeria do Mezanino.',
    );
  });

  testWidgets('Destino em inglês: título, filtros e resultados', (t) async {
    await abrirCom(t, const Preferences(language: AppLanguage.en));
    expect(find.text('Where do you want to go?'), findsOneWidget);
    expect(find.text('Floor: All'), findsOneWidget);
    expect(find.text('Accessible restroom'), findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.textContaining('closest first'), findsOneWidget);
    // Nome próprio fica; piso e categoria são traduzidos.
    expect(find.text('Livraria Página'), findsOneWidget);
    expect(find.text('Ground floor · Stores'), findsWidgets);
    expect(find.text('Para onde você quer ir?'), findsNothing);
  });

  testWidgets('Rota em inglês, com resumo falado quando o áudio está ligado', (
    t,
  ) async {
    Voz.historico.clear();
    final ctrl = await abrirCom(
      t,
      const Preferences(
        language: AppLanguage.en,
        avoidStairs: true,
        audioGuidance: true,
      ),
    );
    await d.tocar(t, find.text('Praça de Alimentação'));
    expect(find.text('Route to'), findsOneWidget);
    expect(find.text('Uses elevator'), findsOneWidget);
    expect(find.text('Step by step'), findsOneWidget);
    expect(find.textContaining('Take the elevator'), findsOneWidget);
    final resumos = Voz.historico.where(
      (f) => f.startsWith('Route to Praça de Alimentação:'),
    );
    expect(resumos, hasLength(1));

    // Um rebuild (troca de preferência) não repete a fala.
    ctrl.update((p) => p.copyWith(highContrast: true));
    await t.pumpAndSettle();
    expect(Voz.historico.where((f) => f.startsWith('Route to')), hasLength(1));
  });

  testWidgets('Sem rota em espanhol: motivo traduzido e anunciado', (t) async {
    Voz.historico.clear();
    await abrirCom(
      t,
      const Preferences(
        language: AppLanguage.es,
        avoidStairs: true,
        audioGuidance: true,
      ),
    );
    expect(find.text('¿Adónde quieres ir?'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Solo hay camino con escaleras'),
      300,
      scrollable: d.lista,
    );
    await d.tocar(t, find.text('Galeria do Mezanino'));
    expect(
      find.text('No hay camino sin escaleras hasta Galeria do Mezanino.'),
      findsOneWidget,
    );
    expect(find.text('Elegir otro destino'), findsOneWidget);
    expect(
      Voz.historico,
      contains('No hay camino sin escaleras hasta Galeria do Mezanino.'),
    );
  });

  testWidgets('Sem áudio, nada é falado', (t) async {
    Voz.historico.clear();
    await abrirCom(t, const Preferences(avoidStairs: true));
    await d.tocar(t, find.text('Praça de Alimentação'));
    expect(Voz.historico, isEmpty);
  });

  testWidgets('"Mensagens rápidas em destaque" mostra o botão nas duas telas', (
    t,
  ) async {
    await abrirCom(t, const Preferences(quickMessages: true));
    expect(
      find.widgetWithText(FloatingActionButton, 'Mensagens rápidas'),
      findsOneWidget,
    );
    await d.tocar(t, find.text('Praça de Alimentação'));
    expect(
      find.widgetWithText(FloatingActionButton, 'Mensagens rápidas'),
      findsOneWidget,
    );
  });

  testWidgets('Sem a preferência, o botão não aparece', (t) async {
    await abrirCom(t, const Preferences());
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
