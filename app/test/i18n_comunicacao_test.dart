// Comunicação, câmera e Ajuda+ no idioma do visitante, com voz opcional e
// mensagens rápidas.

import 'package:acessa_plus/app/i18n/i18n.dart';
import 'package:acessa_plus/app/theme/app_theme.dart';
import 'package:acessa_plus/app/theme/tokens.dart';
import 'package:acessa_plus/core/voz/voz.dart';
import 'package:acessa_plus/data/repositories/repositorios.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/domain/models/comunicacao.dart';
import 'package:acessa_plus/domain/rules/assistencia.dart';
import 'package:acessa_plus/domain/rules/procura.dart';
import 'package:acessa_plus/features/ajuda/ajuda_screen.dart';
import 'package:acessa_plus/features/comunicacao/cartao_ajuda_screen.dart';
import 'package:acessa_plus/features/ultimo_metro/encontrar_screen.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ComunicacaoRepository {
  @override
  Future<List<FraseTraduzida>> cartoesAjuda() async => const [
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
  ];

  @override
  Future<List<CategoriaMensagens>> mensagensRapidas() async => const [
    CategoriaMensagens(
      categoria: FraseTraduzida(
        id: 'C01',
        pt: 'Compras',
        en: 'Shopping',
        es: 'Compras',
      ),
      frases: [
        FraseTraduzida(
          id: 'M01',
          pt: 'Quanto custa?',
          en: 'How much is it?',
          es: '¿Cuánto cuesta?',
        ),
      ],
    ),
  ];

  @override
  Future<List<CartaoComunicacao>> cartoes() async => const [];
  @override
  Future<List<FraseTraduzida>> frasesTraduzidas() async => const [];
  @override
  Future<List<SugestoesDoPonto>> sugestoesPorPonto() async => const [];
}

/// Monta [tela] com as preferências, sem animações (assenta na hora).
Future<void> montar(WidgetTester t, Preferences prefs, Widget tela) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    PreferencesScope(
      controller: PreferencesController(prefs),
      child: MaterialApp(
        theme: buildTheme(prefs),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: tela,
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> girar(WidgetTester t, double graus) async {
  t.widget<Slider>(find.byType(Slider)).onChanged!(graus);
  await t.pumpAndSettle();
}

double _contraste(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (claro, escuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + .05) / (escuro + .05);
}

void main() {
  setUp(Voz.historico.clear);

  test('traduções: descrições da câmera e avisos do Ajuda+', () {
    final d = detectar(const [ObjetoCena(Alvo.cadeira, 20, 1.5)], 20).single;
    expect(traduzir(descrever(d), AppLanguage.en), 'Chair, ahead, close.');
    expect(traduzir(descrever(d), AppLanguage.es), 'Silla, al frente, cerca.');
    const p = PedidoAjuda(
      categoria: CategoriaAjuda.barreira,
      forma: FormaAtendimento.audio,
      local: 'Entrada Principal · Térreo',
    );
    final caminho = p.avancar().avancar();
    expect(
      traduzir(caminho.aviso, AppLanguage.en),
      'Support is on the way to Entrada Principal · Ground floor.',
    );
    // Português continua igual (é a chave).
    expect(traduzir(caminho.aviso, AppLanguage.pt), caminho.aviso);
    for (final c in CategoriaAjuda.values) {
      expect(traduzir(c.texto, AppLanguage.es), isNot(c.texto));
    }
    for (final e in EstadoPedido.values) {
      expect(traduzir(e.texto, AppLanguage.en), isNot(e.texto));
    }
  });

  test('mensagens rápidas: texto com contraste de pelo menos 4,5:1', () {
    for (final c in [
      AcessaColors.standard,
      AcessaColors.calm,
      AcessaColors.highContrast,
    ]) {
      // Bloco em destaque e selo "Em destaque".
      expect(_contraste(c.communication, c.onAccent), greaterThan(4.5));
      // Frases e categorias.
      expect(_contraste(c.surface, c.ink), greaterThan(4.5));
      expect(_contraste(c.primary, c.onPrimary), greaterThan(4.5));
    }
  });

  group('Cartão de ajuda', () {
    testWidgets('em inglês: interface e frases em inglês', (t) async {
      await montar(
        t,
        const Preferences(language: AppLanguage.en),
        CartaoAjudaScreen(repositorio: _Repo()),
      );
      expect(find.text('Help card'), findsOneWidget);
      expect(find.text('Show someone'), findsOneWidget);
      expect(find.text('The person reading speaks'), findsOneWidget);
      expect(find.text('Hello, I need help.'), findsOneWidget);
      expect(find.text('Quick messages'), findsOneWidget);
      expect(find.text('Mostrar para alguém'), findsNothing);

      await t.tap(find.text('Hello, I need help.'));
      await t.pumpAndSettle();
      // Para quem lê: português (padrão), inclusive o botão "Ouvir".
      expect(find.text('Olá, preciso de ajuda.'), findsOneWidget);
      expect(find.text('Ouvir'), findsOneWidget);
      // Metade do visitante: inglês.
      expect(find.text('You are showing:'), findsOneWidget);
      expect(find.text('Face to face'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Trocar quem lê muda o botão "Ouvir" para o idioma dele.
      await t.tap(find.text('Español'));
      await t.pumpAndSettle();
      expect(find.text('Escuchar'), findsOneWidget);
    });

    testWidgets('"Ouvir" fala no idioma de quem lê, mesmo sem áudio', (
      t,
    ) async {
      await montar(
        t,
        const Preferences(),
        CartaoAjudaScreen(repositorio: _Repo()),
      );
      await t.tap(find.text('Olá, preciso de ajuda.'));
      await t.pumpAndSettle();
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      await t.tap(find.text('Listen'));
      await t.pumpAndSettle();
      expect(Voz.historico, contains('Hello, I need help.'));

      // A resposta só vira voz com "Orientações por áudio" ligado.
      Voz.historico.clear();
      await t.tap(find.text('Yes'));
      await t.pumpAndSettle();
      expect(find.text('Resposta: Sim'), findsOneWidget);
      expect(Voz.historico, isEmpty);
    });

    testWidgets('com áudio, a resposta é falada no idioma do visitante', (
      t,
    ) async {
      await montar(
        t,
        const Preferences(language: AppLanguage.es, audioGuidance: true),
        CartaoAjudaScreen(repositorio: _Repo()),
      );
      await t.tap(find.text('Hola, necesito ayuda.'));
      await t.pumpAndSettle();
      await t.tap(find.text('Sim'));
      await t.pumpAndSettle();
      expect(find.text('Respuesta: Sí'), findsOneWidget);
      expect(Voz.historico.last, 'Respuesta: Sí');
    });

    testWidgets('mensagens rápidas em destaque: acima das frases e abrem o '
        'cartão com a tradução para quem lê', (t) async {
      await montar(
        t,
        const Preferences(language: AppLanguage.en, quickMessages: true),
        CartaoAjudaScreen(repositorio: _Repo()),
      );
      final secao = t.getTopLeft(find.text('Quick messages')).dy;
      final frase = t.getTopLeft(find.text('Hello, I need help.')).dy;
      expect(secao, lessThan(frase));
      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);

      await t.tap(find.text('How much is it?'));
      await t.pumpAndSettle();
      // Grande, para quem lê (português), e embaixo no idioma do visitante.
      expect(find.text('Quanto custa?'), findsOneWidget);
      expect(find.text('You are showing:'), findsOneWidget);
      expect(find.text('How much is it?'), findsOneWidget);
    });

    testWidgets('sem a preferência, as mensagens rápidas vêm depois', (
      t,
    ) async {
      await montar(
        t,
        const Preferences(),
        CartaoAjudaScreen(repositorio: _Repo()),
      );
      final secao = t.getTopLeft(find.text('Mensagens rápidas')).dy;
      final frase = t.getTopLeft(find.text('Olá, preciso de ajuda.')).dy;
      expect(secao, greaterThan(frase));
      expect(find.text('Em destaque'), findsNothing);
    });
  });

  group('Câmera', () {
    testWidgets('em espanhol: título, estado e avisos traduzidos', (t) async {
      await montar(
        t,
        const Preferences(language: AppLanguage.es),
        const EncontrarScreen(vibrar: false),
      );
      expect(find.text('Encontrar con la cámara'), findsOneWidget);
      expect(find.text('Buscando: Puerta'), findsOneWidget);
      expect(find.text('Frío: gira despacio'), findsOneWidget);
      expect(find.textContaining('a la altura del pecho'), findsOneWidget);
      expect(find.text('Cómo usar'), findsOneWidget);

      await girar(t, 45);
      expect(find.text('¡Justo al frente!'), findsOneWidget);
      expect(find.text('Puerta, al frente, a pocos pasos.'), findsOneWidget);

      // "O que tem aqui?" traduz cada objeto inteiro.
      await t.tap(find.byTooltip('Buscar: Mostrador'));
      await t.pumpAndSettle();
      await girar(t, -40);
      await t.tap(find.text('¿Qué hay aquí?'));
      await t.pumpAndSettle();
      expect(
        find.text('Mostrador, al frente, lejos. Caja, a la izquierda, lejos.'),
        findsOneWidget,
      );
      // Sem áudio ligado, nada é falado.
      expect(Voz.historico, isEmpty);
    });

    testWidgets('com áudio: fala quando o alvo fica bem à frente', (t) async {
      await montar(
        t,
        const Preferences(audioGuidance: true),
        const EncontrarScreen(vibrar: false),
      );
      // A instrução inicial também é falada.
      expect(Voz.historico.single, startsWith('Procurando: Porta.'));
      await girar(t, 45);
      expect(Voz.historico.last, 'Porta, à frente, a poucos passos.');
    });

    testWidgets('com áudio em inglês: fala traduzido', (t) async {
      await montar(
        t,
        const Preferences(audioGuidance: true, language: AppLanguage.en),
        const EncontrarScreen(vibrar: false),
      );
      await girar(t, 45);
      expect(Voz.historico.last, 'Door, ahead, a few steps away.');
    });

    testWidgets('mensagens rápidas: botão flutuante sem cobrir a lista', (
      t,
    ) async {
      await montar(
        t,
        const Preferences(quickMessages: true),
        const EncontrarScreen(vibrar: false),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Mensagens rápidas'), findsOneWidget);
    });
  });

  group('Ajuda+', () {
    testWidgets('em inglês: categorias, etapas e estados traduzidos', (
      t,
    ) async {
      final dados = await t.runAsync(() => ShoppingData.carregar());
      await montar(
        t,
        const Preferences(language: AppLanguage.en),
        AjudaScreen(dados: dados),
      );
      expect(find.text('What is happening?'), findsOneWidget);
      expect(find.text('I found a barrier on the way'), findsOneWidget);
      expect(find.text('Encontrei uma barreira no caminho'), findsNothing);
      expect(find.text('Entrada Principal · Ground floor'), findsWidgets);

      Future<void> tocar(String rotulo) async {
        await t.ensureVisible(find.text(rotulo));
        await t.pumpAndSettle();
        await t.tap(find.text(rotulo));
        await t.pumpAndSettle();
      }

      await tocar('I found a barrier on the way');
      await tocar('Review request');
      expect(find.text('Check your request'), findsOneWidget);
      await tocar('Confirm and ask for help');
      expect(find.text('Tracking'), findsOneWidget);
      expect(find.text('Request registered'), findsOneWidget);
      expect(find.text('Current stage'), findsOneWidget);
    });

    testWidgets('com áudio: mudanças de estado são faladas', (t) async {
      final dados = await t.runAsync(() => ShoppingData.carregar());
      await montar(
        t,
        const Preferences(audioGuidance: true, language: AppLanguage.en),
        AjudaScreen(dados: dados),
      );
      await t.tap(find.text('I need someone to accompany me'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Review request'));
      await t.pumpAndSettle();
      await t.tap(find.text('Review request'));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirm and ask for help'));
      await t.pumpAndSettle();
      expect(Voz.historico.last, 'Request registered.');
      await t.tap(find.text('Next stage (demo)'));
      await t.pumpAndSettle();
      expect(Voz.historico.last, 'A staff member received your request.');
    });

    testWidgets('mensagens rápidas: botão flutuante com o destino', (t) async {
      final dados = await t.runAsync(() => ShoppingData.carregar());
      await montar(
        t,
        const Preferences(quickMessages: true),
        AjudaScreen(dados: dados, destino: 'Praça de Alimentação'),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
