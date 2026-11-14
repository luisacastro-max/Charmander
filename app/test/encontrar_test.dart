// "Último metro": encontrar objetos com a câmera (protótipo simulado).

import 'package:acessa_plus/app/theme/app_theme.dart';
import 'package:acessa_plus/domain/rules/procura.dart';
import 'package:acessa_plus/features/ultimo_metro/encontrar_screen.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navegacao_test.dart' as nav;

/// Abre a tela isolada. Por padrão com movimento reduzido (como pede o
/// sistema): o radar não roda e `pumpAndSettle` assenta na hora.
Future<void> abrir(WidgetTester t, {bool animar = false}) async {
  t.view.physicalSize = const Size(1080, 6000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: buildTheme(const Preferences()),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: !animar),
        child: child!,
      ),
      home: const EncontrarScreen(vibrar: false),
    ),
  );
  if (animar) {
    // O radar gira sem parar: avança o relógio em vez de esperar assentar.
    await t.pump(const Duration(seconds: 2));
  } else {
    await t.pumpAndSettle();
  }
}

Future<void> girar(WidgetTester t, double graus) async {
  t.widget<Slider>(find.byType(Slider)).onChanged!(graus);
  await t.pumpAndSettle();
}

void main() {
  group('Regras de procura', () {
    const cena = [ObjetoCena(Alvo.cadeira, 20, 1.5)];

    test('a câmera só vê o que está no campo de visão', () {
      expect(detectar(cena, 0).single.alvo, Alvo.cadeira);
      expect(detectar(cena, -40), isEmpty);
      // Atravessa o -180/180 sem se perder.
      expect(
        detectar(const [ObjetoCena(Alvo.porta, 175, 1)], -175),
        hasLength(1),
      );
    });

    test('quente ou frio: pulsos aceleram até ficar quase contínuos', () {
      final fora = sinalPara(Alvo.cadeira, detectar(cena, -60));
      final borda = sinalPara(Alvo.cadeira, detectar(cena, -5));
      final centro = sinalPara(Alvo.cadeira, detectar(cena, 20));

      expect(fora.encontrado, isFalse);
      expect(borda.encontrado, isTrue);
      expect(borda.centralizado, isFalse);
      expect(centro.centralizado, isTrue);
      expect(fora.intervalo > borda.intervalo, isTrue);
      expect(borda.intervalo > centro.intervalo, isTrue);
    });

    test('frases curtas: objeto, lado e distância', () {
      expect(descrever(detectar(cena, 20).single), 'Cadeira, à frente, perto.');
      expect(descrever(detectar(cena, -5).single), contains('à direita'));
      expect(descreverCena(const []), contains('Gire devagar'));
    });
  });

  testWidgets('Começa procurando a porta e avisa quando está à frente', (
    t,
  ) async {
    await abrir(t);
    expect(find.text('Procurando: Porta'), findsOneWidget);
    expect(find.textContaining('altura do peito'), findsOneWidget);
    expect(find.text('Frio: gire devagar'), findsOneWidget);
    expect(find.textContaining('Demonstração'), findsOneWidget);

    await girar(t, 30);
    expect(find.text('Quente: está na imagem'), findsOneWidget);

    await girar(t, 45);
    expect(find.text('Bem à frente!'), findsOneWidget);
    expect(find.text('Porta, à frente, a poucos passos.'), findsOneWidget);
  });

  testWidgets('Troca o objeto e descreve o ambiente', (t) async {
    await abrir(t);
    await t.tap(find.byTooltip('Procurar Balcão'));
    await t.pumpAndSettle();
    expect(find.text('Procurando: Balcão'), findsOneWidget);

    await girar(t, -40);
    await t.tap(find.text('O que tem aqui?'));
    await t.pumpAndSettle();
    expect(find.textContaining('Balcão, à frente, longe.'), findsOneWidget);
    expect(find.textContaining('Caixa, à esquerda, longe.'), findsOneWidget);
  });

  testWidgets('Gestos amplos na área da câmera', (t) async {
    await abrir(t);
    final area = find.byType(AspectRatio);

    await t.fling(area, const Offset(-300, 0), 1000);
    await t.pumpAndSettle();
    expect(find.text('Procurando: Balcão'), findsOneWidget);

    await t.fling(area, const Offset(300, 0), 1000);
    await t.pumpAndSettle();
    expect(find.text('Procurando: Porta'), findsOneWidget);

    await t.fling(area, const Offset(0, -300), 1000);
    await t.pumpAndSettle();
    expect(find.textContaining('Não reconheço nada aqui'), findsOneWidget);
  });

  testWidgets('Leitor de tela: área ajustável troca o objeto e tem a ação '
      '"O que tem aqui?"', (t) async {
    final semantica = t.ensureSemantics();
    await abrir(t);
    final no = find.bySemanticsLabel(RegExp('^Área da câmera'));
    expect(
      t.getSemantics(no),
      matchesSemantics(
        label: 'Área da câmera. Objeto procurado',
        value: 'Porta',
        increasedValue: 'Balcão',
        decreasedValue: 'Banheiro',
        hint:
            'Deslize para cima ou para baixo para trocar o objeto. '
            'Toque duas vezes para saber onde ele está.',
        hasTapAction: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        customActions: const [CustomSemanticsAction(label: 'O que tem aqui?')],
      ),
    );

    t.semantics.performAction(
      find.semantics.byLabel(RegExp('^Área da câmera')),
      SemanticsAction.increase,
    );
    await t.pumpAndSettle();
    expect(find.text('Procurando: Balcão'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('Ao chegar ao destino, oferece "Encontrar com a câmera"', (
    t,
  ) async {
    await nav.abrirDestino(t);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    await nav.tocar(t, find.text('Iniciar navegação'));
    await nav.simularAte(t, find.text('Você chegou!'));

    final botao = find.text('Encontrar com a câmera');
    await t.scrollUntilVisible(botao, 300, scrollable: nav.lista);
    await t.ensureVisible(botao);
    await t.pumpAndSettle();
    await t.tap(botao);
    // No app real o movimento está ligado e o radar gira sem parar:
    // avança o relógio (transição + entradas escalonadas) sem
    // pumpAndSettle.
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(EncontrarScreen), findsOneWidget);
    expect(find.text('Procurando: Porta'), findsOneWidget);
  });

  group('Movimento', () {
    testWidgets('Com movimento: radar anima, mira trava e o estado continua '
        'em texto', (t) async {
      await abrir(t, animar: true);
      // O radar está vivo (pede novos quadros).
      expect(t.binding.hasScheduledFrame, isTrue);
      expect(find.text('Frio: gire devagar'), findsOneWidget);

      t.widget<Slider>(find.byType(Slider)).onChanged!(45);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Bem à frente!'), findsOneWidget);
      expect(find.text('Porta, à frente, a poucos passos.'), findsOneWidget);

      await t.tap(find.byTooltip('Procurar Balcão'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Procurando: Balcão'), findsOneWidget);
      expect(find.text('Procurando: Porta'), findsNothing);

      // Ao sair da tela, o relógio do radar é descartado sem erro.
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Com movimento reduzido: nada fica em loop', (t) async {
      await abrir(t);
      expect(t.binding.hasScheduledFrame, isFalse);
      await girar(t, 45);
      expect(t.binding.hasScheduledFrame, isFalse);
      expect(find.text('Bem à frente!'), findsOneWidget);
    });

    testWidgets('Alto contraste: aviso centralizado com texto escuro', (
      t,
    ) async {
      t.view.physicalSize = const Size(1080, 6000);
      t.view.devicePixelRatio = 2.5;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(const Preferences(highContrast: true)),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const EncontrarScreen(vibrar: false),
        ),
      );
      await t.pumpAndSettle();
      await girar(t, 45);
      final aviso = t.widget<Text>(
        find.text('Porta, à frente, a poucos passos.'),
      );
      expect(aviso.style?.color, const Color(0xFF000000));
    });
  });
}
