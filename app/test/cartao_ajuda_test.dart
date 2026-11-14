// Cartão de ajuda: mostrar uma frase a outra pessoa e receber a resposta.

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/app/theme/app_theme.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/data/repositories/json_repositorios.dart';
import 'package:acessa_plus/data/repositories/repositorios.dart';
import 'package:acessa_plus/domain/models/comunicacao.dart';
import 'package:acessa_plus/features/comunicacao/cartao_ajuda_screen.dart';
import 'package:acessa_plus/features/comunicacao/cartao_animacoes.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navegacao_test.dart' as nav;

class _Repo implements ComunicacaoRepository {
  @override
  Future<List<FraseTraduzida>> cartoesAjuda() async => const [
    FraseTraduzida(
      id: 'A01',
      icone: 'levar',
      pt: 'Pode me levar até {destino}?',
      en: 'Can you take me to {destino}?',
      es: '¿Puede llevarme a {destino}?',
    ),
    FraseTraduzida(
      id: 'A02',
      icone: 'ajuda',
      pt: 'Olá, preciso de ajuda.',
      en: 'Hello, I need help.',
      es: 'Hola, necesito ayuda.',
    ),
  ];

  @override
  Future<List<FraseTraduzida>> respostasRapidas() async => const [
    FraseTraduzida(id: 'R01', pt: 'Sim', en: 'Yes', es: 'Sí'),
    FraseTraduzida(id: 'R03', pt: 'Me siga', en: 'Follow me', es: 'Sígame'),
  ];

  @override
  Future<List<CartaoComunicacao>> cartoes() async => const [];
  @override
  Future<List<CategoriaMensagens>> mensagensRapidas() async => const [];
  @override
  Future<List<FraseTraduzida>> frasesTraduzidas() async => const [];
  @override
  Future<List<SugestoesDoPonto>> sugestoesPorPonto() async => const [];
}

Future<void> abrir(
  WidgetTester t, {
  String? destino,
  AppLanguage idioma = AppLanguage.pt,
  bool calmo = false,
}) async {
  t.view.physicalSize = const Size(1080, 6000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final prefs = Preferences(language: idioma, calm: calmo);
  await t.pumpWidget(
    PreferencesScope(
      controller: PreferencesController(prefs),
      child: MaterialApp(
        theme: buildTheme(prefs),
        home: CartaoAjudaScreen(destino: destino, repositorio: _Repo()),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  test('dados: frases e respostas completas nos 3 idiomas', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final r = JsonComunicacaoRepository();
    final frases = await r.cartoesAjuda();
    final respostas = await r.respostasRapidas();
    expect(frases, isNotEmpty);
    expect(respostas, isNotEmpty);
    for (final f in [...frases, ...respostas]) {
      expect([f.pt, f.en, f.es].every((s) => s.trim().isNotEmpty), isTrue);
      // O marcador do destino não pode se perder na tradução.
      final marca = f.pt.contains('{destino}');
      expect(f.en.contains('{destino}'), marca, reason: f.id);
      expect(f.es.contains('{destino}'), marca, reason: f.id);
    }
  });

  testWidgets('Sem destino, a frase "levar até" não aparece', (t) async {
    await abrir(t);
    expect(find.text('Olá, preciso de ajuda.'), findsOneWidget);
    expect(find.textContaining('levar até'), findsNothing);
  });

  testWidgets('Estrangeiro mostra em português e lê a resposta em inglês', (
    t,
  ) async {
    await abrir(t, destino: 'Balcão de Informações', idioma: AppLanguage.en);
    // A lista aparece no idioma do visitante.
    await t.tap(find.text('Can you take me to Balcão de Informações?'));
    await t.pumpAndSettle();

    // Para quem lê (padrão: português), letra grande.
    expect(
      find.text('Pode me levar até Balcão de Informações?'),
      findsOneWidget,
    );
    // A metade do visitante segue o idioma dele (inglês).
    expect(find.text('You are showing:'), findsOneWidget);
    expect(find.text('Waiting for an answer…'), findsOneWidget);
    // O botão "Ouvir" fica no idioma de quem lê (português).
    expect(find.text('Ouvir'), findsOneWidget);

    await t.tap(find.text('Me siga'));
    await t.pumpAndSettle();
    expect(find.text('Answer: Follow me'), findsOneWidget);
  });

  testWidgets('Troca o idioma de quem lê e vira frente a frente', (t) async {
    await abrir(t);
    await t.tap(find.text('Olá, preciso de ajuda.'));
    await t.pumpAndSettle();

    await t.tap(find.text('Español'));
    await t.pumpAndSettle();
    expect(find.text('Hola, necesito ayuda.'), findsOneWidget);
    expect(find.text('Sí'), findsOneWidget);

    // A metade de cima gira (animada) meia volta: cos(ângulo) vai de 1 a -1.
    double cosGiro() =>
        t.widget<Transform>(find.byKey(chaveGiroLeitor)).transform.entry(0, 0);
    expect(cosGiro(), closeTo(1, 1e-9));
    await t.tap(find.text('Frente a frente'));
    await t.pumpAndSettle();
    expect(cosGiro(), closeTo(-1, 1e-9));
    expect(find.text('Desvirar'), findsOneWidget);
    // Continua tocável de cabeça para baixo.
    await t.tap(find.text('Sí'));
    await t.pumpAndSettle();
    expect(find.text('Resposta: Sim'), findsOneWidget);

    await t.tap(find.text('Fechar'));
    await t.pumpAndSettle();
    expect(find.text('Mostrar para alguém'), findsOneWidget);
  });

  testWidgets('Com redução de estímulos, tudo aparece pronto, sem animar', (
    t,
  ) async {
    await abrir(t, calmo: true);
    bool tudoVisivel() => t
        .widgetList<Opacity>(find.byType(Opacity))
        .every((o) => o.opacity == 1);
    double cosGiro() =>
        t.widget<Transform>(find.byKey(chaveGiroLeitor)).transform.entry(0, 0);

    expect(tudoVisivel(), isTrue);
    await t.tap(find.text('Olá, preciso de ajuda.'));
    await t.pump();
    await t.pump();
    // Um quadro basta: o cartão já está aberto e completo.
    expect(find.text('Você está mostrando:'), findsOneWidget);
    expect(find.text('Aguardando resposta…'), findsOneWidget);
    expect(tudoVisivel(), isTrue);

    await t.tap(find.text('Frente a frente'));
    await t.pump();
    expect(cosGiro(), closeTo(-1, 1e-9));

    await t.tap(find.text('Sim'));
    await t.pump();
    await t.pump();
    expect(find.text('Resposta: Sim'), findsOneWidget);
    expect(find.text('Aguardando resposta…'), findsNothing);
  });

  testWidgets('Abre pelo botão da navegação, já com o destino', (t) async {
    await nav.abrirDestino(t);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    await nav.tocar(t, find.text('Iniciar navegação'));
    await t.tap(find.byTooltip('Cartão de ajuda'));
    // Lê o JSON de verdade (fora do relógio falso dos testes).
    // (o indicador de carregamento gira, então não dá para esperar assentar).
    final frase = find.text('Pode me levar até Praça de Alimentação?');
    for (var i = 0; i < 50 && frase.evaluate().isEmpty; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pumpAndSettle();
    expect(find.text('Cartão de ajuda'), findsOneWidget);
    expect(
      find.text('Pode me levar até Praça de Alimentação?'),
      findsOneWidget,
    );
  });

  testWidgets('Na tela inicial, Comunicação Universal abre os cartões', (
    t,
  ) async {
    t.view.physicalSize = const Size(1080, 9000);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    final dados = await t.runAsync(() => ShoppingData.carregar());
    await t.pumpWidget(
      AcessaApp(controller: PreferencesController(), dados: dados),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Comunicação Universal'));
    final frase = find.text('Olá, preciso de ajuda.');
    for (var i = 0; i < 50 && frase.evaluate().isEmpty; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Mostrar para alguém'), findsOneWidget);
    expect(frase, findsOneWidget);
    // Sem rota, não há destino para "levar até".
    expect(find.textContaining('levar até'), findsNothing);
  });
}
