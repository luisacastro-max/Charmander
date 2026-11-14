// Testes de tela da Etapa 3a — "Para onde você quer ir?" e resumo da rota.
// Cenários BDD: docs/qa/etapa-3a-destino.feature

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<PreferencesController> abrirDestino(
  WidgetTester t, {
  Preferences prefs = const Preferences(),
}) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  // Carrega os JSON fora do relógio simulado do teste.
  final dados = await t.runAsync(() => ShoppingData.carregar());
  final ctrl = PreferencesController(prefs);
  await t.pumpWidget(AcessaApp(controller: ctrl, dados: dados));
  await t.pumpAndSettle();
  await t.tap(find.text('Começar'));
  await t.pumpAndSettle();
  final continuar = find.text('Continuar');
  await t.scrollUntilVisible(continuar, 300, scrollable: lista);
  await t.tap(continuar);
  await t.pumpAndSettle();
  return ctrl;
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 300, scrollable: lista);
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Rolagem vertical da tela atual (o campo de busca também tem um
/// Scrollable, horizontal, que não serve aqui).
final lista = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .last;

void main() {
  testWidgets('Depois das preferências vem "Para onde você quer ir?"', (
    t,
  ) async {
    await abrirDestino(t);
    expect(find.text('Para onde você quer ir?'), findsOneWidget);
    expect(find.text('Você está aqui'), findsOneWidget);
    expect(find.textContaining('(simulado)'), findsWidgets);
  });

  testWidgets('Atalho "Banheiro acessível" lista os dois pisos, mais perto '
      'primeiro', (t) async {
    await abrirDestino(t);
    await tocar(t, find.text('Banheiro acessível'));
    final terreo = find.text('Banheiro acessível do Térreo');
    final segundo = find.text('Banheiro acessível do 2º piso');
    expect(terreo, findsOneWidget);
    expect(segundo, findsOneWidget);
    expect(t.getTopLeft(terreo).dy, lessThan(t.getTopLeft(segundo).dy));
  });

  testWidgets('RF07/RF09: busca sem acento e busca sem resultado', (t) async {
    await abrirDestino(t);
    await t.enterText(find.byType(TextField), 'fraldario');
    await t.pumpAndSettle();
    expect(find.text('Espaço Família'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'xyz');
    await t.pumpAndSettle();
    expect(find.textContaining('Nada encontrado'), findsOneWidget);
    await tocar(t, find.text('Limpar busca e filtros'));
    expect(find.textContaining('Nada encontrado'), findsNothing);
  });

  testWidgets('RF08: filtro por piso', (t) async {
    await abrirDestino(t);
    await tocar(t, find.text('Piso: Todos'));
    await t.tap(find.text('2º piso').last);
    await t.pumpAndSettle();
    expect(find.text('Piso: 2º piso'), findsOneWidget);
    expect(find.text('Praça de Alimentação'), findsOneWidget);
    expect(find.text('Vitrine Moda'), findsNothing);
  });

  testWidgets('RN03: com "sem escadas", rota até a Praça usa elevador', (
    t,
  ) async {
    await abrirDestino(t, prefs: const Preferences(avoidStairs: true));
    await tocar(t, find.text('Praça de Alimentação'));
    expect(find.text('Rota até'), findsOneWidget);
    expect(find.text('Sem escadas'), findsOneWidget);
    expect(find.text('Usa elevador'), findsOneWidget);
    expect(find.textContaining('Pegue o elevador'), findsOneWidget);
    expect(find.textContaining('degraus'), findsNothing);
  });

  testWidgets('RN04: destino só com escada informa e mantém a preferência', (
    t,
  ) async {
    final ctrl = await abrirDestino(
      t,
      prefs: const Preferences(avoidStairs: true),
    );
    await t.scrollUntilVisible(
      find.text('Só há caminho com escadas'),
      300,
      scrollable: lista,
    );
    await tocar(t, find.text('Galeria do Mezanino'));
    expect(find.textContaining('Não há caminho sem escadas'), findsOneWidget);
    expect(find.textContaining('continua ativa'), findsOneWidget);
    expect(find.text('Revisar minhas preferências'), findsOneWidget);
    expect(ctrl.prefs.avoidStairs, isTrue);
  });

  testWidgets('Rota com degraus avisa quando "sem escadas" está desligado', (
    t,
  ) async {
    await abrirDestino(t);
    await tocar(t, find.text('Sabor da Terra'));
    expect(find.text('Tem degraus'), findsOneWidget);
    expect(find.textContaining('Esta rota tem degraus'), findsOneWidget);
  });

  testWidgets('RF51: trocar o ponto simulado muda "Você está aqui"', (t) async {
    await abrirDestino(t);
    await t.tap(find.text('Trocar'));
    await t.pumpAndSettle();
    expect(find.text('Simular que estou perto de…'), findsOneWidget);
    await t.tap(find.text('Praça de Alimentação').last);
    await t.pumpAndSettle();
    expect(find.textContaining('2º piso · beacon BLE-26'), findsOneWidget);
  });

  testWidgets('RNF08: destino sem horário mostra "Não informado"', (t) async {
    await abrirDestino(t);
    await tocar(t, find.text('Livraria Página'));
    expect(
      find.textContaining('Horário: Não informado', findRichText: true),
      findsOneWidget,
    );
  });
}
