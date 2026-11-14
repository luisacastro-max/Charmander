// Testes de tela da Etapa 3b — paradas, bússola guiada e mapa interativo.
// Cenários BDD: docs/qa/etapa-3b-navegacao.feature

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/features/destino/destino_screen.dart';
import 'package:acessa_plus/features/navegacao/bussola.dart';
import 'package:acessa_plus/features/navegacao/mapa_interativo.dart';
import 'package:acessa_plus/features/navegacao/navegacao_screen.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final lista = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .last;

Future<void> abrirDestino(
  WidgetTester t, {
  Preferences prefs = const Preferences(avoidStairs: true),
}) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final dados = await t.runAsync(() => ShoppingData.carregar());
  await t.pumpWidget(
    AcessaApp(controller: PreferencesController(prefs), dados: dados),
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Começar'));
  await t.pumpAndSettle();
  await tocar(t, find.text('Continuar'));
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 300, scrollable: lista);
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
  // Deixa terminar as entradas escalonadas (Future.delayed).
  await t.pump(const Duration(seconds: 1));
  await t.pumpAndSettle();
}

/// Rota "Elevadores — Térreo" e, depois, "Praça de Alimentação".
Future<void> montarRotaComParada(WidgetTester t) async {
  await abrirDestino(t);
  await tocar(t, find.text('Elevadores — Térreo'));
  expect(find.text('Rota até'), findsOneWidget);
  await tocar(t, find.text('Adicionar outra parada'));
  expect(find.text('Qual a próxima parada?'), findsOneWidget);
  expect(find.text('Depois de'), findsOneWidget);
  expect(find.text('Trocar'), findsNothing);
  await tocar(t, find.text('Praça de Alimentação'));
}

Future<void> simularAte(WidgetTester t, Finder alvo) async {
  for (var i = 0; i < 20 && alvo.evaluate().isEmpty; i++) {
    await tocar(t, find.textContaining('Simular chegada'));
  }
  expect(alvo, findsOneWidget);
}

void main() {
  testWidgets('Paradas como no app de transporte: elevador e depois a '
      'Praça de Alimentação', (t) async {
    await montarRotaComParada(t);
    expect(find.text('Parada 1'), findsOneWidget);
    expect(find.text('Destino final'), findsOneWidget);
    expect(find.text('2 paradas'), findsOneWidget);
    expect(find.textContaining('Até a parada 1: Elevadores'), findsOneWidget);
    expect(
      find.textContaining('Até o destino final: Praça de Alimentação'),
      findsOneWidget,
    );
    // O destino final vira o título da rota.
    expect(
      find.descendant(
        of: find.byType(Row),
        matching: find.text('Praça de Alimentação'),
      ),
      findsWidgets,
    );
  });

  testWidgets('Como no Uber: "+" na busca adiciona parada antes do destino', (
    t,
  ) async {
    await abrirDestino(t);
    await tocar(t, find.byTooltip('Adicionar parada'));
    expect(find.text('Parada 1'), findsOneWidget);
    await tocar(t, find.text('Elevadores — Térreo'));
    await t.scrollUntilVisible(
      find.textContaining('é a parada 1'),
      -300,
      scrollable: lista,
    );
    expect(find.textContaining('é a parada 1'), findsOneWidget);
    expect(find.byTooltip('Remover Elevadores — Térreo'), findsOneWidget);
    // Agora a busca é do destino; distâncias contadas a partir do elevador.
    await tocar(t, find.text('Praça de Alimentação'));
    expect(find.text('Rota até'), findsOneWidget);
    expect(find.text('2 paradas'), findsOneWidget);
    expect(find.textContaining('Até a parada 1: Elevadores'), findsOneWidget);
  });

  testWidgets('Reordenar e remover paradas recalcula a rota', (t) async {
    await montarRotaComParada(t);
    await tocar(t, find.byTooltip('Mover Praça de Alimentação para antes'));
    expect(
      find.textContaining('Praça de Alimentação agora é a parada 1'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Até o destino final: Elevadores'),
      findsOneWidget,
    );
    await tocar(t, find.byTooltip('Remover Praça de Alimentação'));
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Parada 1'), findsNothing);
    expect(find.byTooltip('Remover Elevadores — Térreo'), findsNothing);
  });

  testWidgets('RN04 com paradas: parada só com escada é apontada e pode ser '
      'removida', (t) async {
    await montarRotaComParada(t);
    await tocar(t, find.text('Adicionar outra parada'));
    await t.scrollUntilVisible(
      find.text('Galeria do Mezanino'),
      300,
      scrollable: lista,
    );
    await tocar(t, find.text('Galeria do Mezanino'));
    expect(find.text('Sem caminho compatível até aqui'), findsOneWidget);
    expect(find.textContaining('Não há caminho sem escadas'), findsOneWidget);
    await tocar(t, find.text('Remover a parada Galeria do Mezanino'));
    expect(find.text('Iniciar navegação'), findsOneWidget);
  });

  testWidgets('RF17–RF22: navegação beacon a beacon, para na parada e chega '
      'ao destino', (t) async {
    await montarRotaComParada(t);
    await tocar(t, find.text('Iniciar navegação'));

    expect(find.textContaining('Parada 1 de 2'), findsOneWidget);
    expect(find.byType(BussolaGuiada), findsOneWidget);
    expect(find.textContaining('Não usa a bússola do celular'), findsOneWidget);
    expect(find.textContaining('(simulado)'), findsNothing);
    expect(find.textContaining('Demonstração'), findsOneWidget);

    await simularAte(t, find.text('Você chegou à parada 1'));
    expect(find.text('Seguir para Praça de Alimentação'), findsOneWidget);
    // Na parada, só segue quando o visitante decide.
    expect(find.textContaining('Simular chegada'), findsNothing);

    await tocar(t, find.text('Seguir para Praça de Alimentação'));
    expect(find.textContaining('Destino final'), findsOneWidget);
    expect(find.textContaining('Pegue o elevador'), findsOneWidget);

    await simularAte(t, find.text('Você chegou!'));
    expect(find.text('Rota concluída'), findsOneWidget);
    await tocar(t, find.text('Escolher novo destino'));
    // Volta para a busca (a lista mantém a rolagem, então o título pode
    // estar fora da tela).
    expect(find.byType(DestinoScreen), findsOneWidget);
    expect(find.byType(NavegacaoScreen), findsNothing);
  });

  testWidgets('RF19/RF48: mapa com zoom, troca de piso e "Ver meu piso"', (
    t,
  ) async {
    final semantica = t.ensureSemantics();
    await abrirDestino(t);
    await tocar(t, find.text('Praça de Alimentação'));
    await tocar(t, find.text('Iniciar navegação'));
    await tocar(t, find.text('Mapa'));

    expect(find.byType(MapaInterativo), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Mapa do Térreo')), findsOneWidget);
    expect(find.text('Térreo (você)'), findsOneWidget);

    // Modo GPS: segue você e gira na direção da caminhada.
    expect(
      find.bySemanticsLabel(RegExp('gira na direção da caminhada')),
      findsOneWidget,
    );
    expect(find.text('Recentralizar'), findsNothing);
    await tocar(t, find.byTooltip('Aproximar o mapa'));
    await tocar(t, find.byTooltip('Afastar o mapa'));

    // Bússola: alterna para "norte do mapa para cima".
    await tocar(t, find.byTooltip('Deixar o norte do mapa para cima'));
    expect(
      find.bySemanticsLabel(RegExp('norte do mapa para cima')),
      findsOneWidget,
    );
    await tocar(t, find.byTooltip('Girar o mapa na direção da caminhada'));

    // Arrastar solta o mapa; "Recentralizar" volta a seguir.
    await t.drag(
      find.bySemanticsLabel(RegExp('^Mapa do')),
      const Offset(60, 40),
    );
    await t.pumpAndSettle();
    expect(find.text('Recentralizar'), findsOneWidget);
    await tocar(t, find.text('Recentralizar'));
    expect(find.text('Recentralizar'), findsNothing);

    await tocar(t, find.byTooltip('Ver a rota inteira'));
    expect(find.text('Recentralizar'), findsOneWidget);
    await tocar(t, find.text('Recentralizar'));

    await tocar(t, find.widgetWithText(ChoiceChip, '2º piso'));
    expect(find.text('Vendo o 2º piso. Você está no Térreo.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Mapa do 2º piso.*Praça de Alimentação')),
      findsOneWidget,
    );
    await tocar(t, find.text('Ver meu piso'));
    expect(find.textContaining('Vendo o'), findsNothing);

    // Ao subir de elevador, o mapa acompanha o visitante.
    await simularAte(t, find.text('2º piso (você)'));
    semantica.dispose();
  });

  test('direção da seta em texto para leitores de tela', () {
    expect(direcaoEmTexto(0), 'para cima no mapa');
    expect(direcaoEmTexto(90), 'à direita no mapa');
    expect(direcaoEmTexto(200), 'para baixo no mapa');
    expect(direcaoEmTexto(350), 'para cima no mapa');
  });
}
