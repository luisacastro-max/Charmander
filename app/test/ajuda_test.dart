// Ajuda+ (RF36–RF43): pedido, revisão e acompanhamento simulado.

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/domain/rules/assistencia.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navegacao_test.dart' as nav;

Future<void> abrirAjuda(
  WidgetTester t, {
  Preferences prefs = const Preferences(),
}) async {
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final dados = await t.runAsync(() => ShoppingData.carregar());
  await t.pumpWidget(
    AcessaApp(controller: PreferencesController(prefs), dados: dados),
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Ajuda+'));
  await t.pumpAndSettle();
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  group('Pedido de ajuda (regras)', () {
    const p = PedidoAjuda(
      categoria: CategoriaAjuda.barreira,
      forma: FormaAtendimento.presencial,
      local: 'Entrada Principal · Térreo',
    );

    test('RF40: avança pelos 4 estados e para na conclusão', () {
      var x = p;
      for (var i = 0; i < 6; i++) {
        x = x.avancar();
      }
      expect(x.estado, EstadoPedido.concluida);
      expect(x.emAndamento, isFalse);
    });

    test('RF41: cancela só em andamento', () {
      final c = p.avancar().cancelar();
      expect(c.cancelado, isTrue);
      expect(c.avancar().estado, EstadoPedido.atribuido);
      expect(c.aviso, 'Solicitação cancelada.');

      var fim = p;
      for (var i = 0; i < 3; i++) {
        fim = fim.avancar();
      }
      expect(fim.cancelar().cancelado, isFalse);
    });
  });

  testWidgets('Da tela inicial: pede, revisa, corrige e acompanha', (t) async {
    await abrirAjuda(t);
    expect(find.text('O que está acontecendo?'), findsOneWidget);
    expect(find.text('Entrada Principal · Térreo'), findsWidgets);

    // Sem escolher a categoria, não avança.
    await tocar(t, find.text('Revisar pedido'));
    expect(find.text('Escolha uma opção para continuar.'), findsOneWidget);

    await tocar(t, find.text('Encontrei uma barreira no caminho'));
    // Frase pronta do local preenche os detalhes (RN14: só ao tocar).
    expect(find.text('Gostaria de um mapa tátil, por favor.'), findsNothing);
    await tocar(t, find.text('Pedir um mapa tátil'));
    expect(find.text('Gostaria de um mapa tátil, por favor.'), findsOneWidget);

    await tocar(t, find.text('Revisar pedido'));
    expect(find.text('Confira seu pedido'), findsOneWidget);
    expect(find.text('Atendimento presencial'), findsOneWidget);

    // RF38: corrigir volta ao formulário com os dados.
    await tocar(t, find.text('Corrigir'));
    await tocar(t, find.text('Mensagem de texto'));
    await tocar(t, find.text('Revisar pedido'));
    expect(find.text('Mensagem de texto'), findsOneWidget);

    await tocar(t, find.text('Confirmar e pedir ajuda'));
    expect(find.text('Acompanhamento'), findsOneWidget);
    expect(find.text('Etapa atual'), findsOneWidget);
    expect(find.textContaining('nenhuma equipe real'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tocar(t, find.text('Avançar etapa (demonstração)'));
    }
    expect(find.text('Avançar etapa (demonstração)'), findsNothing);
    expect(find.text('Cancelar solicitação'), findsNothing);
    // Fora da navegação, não há percurso para retomar.
    expect(find.text('Retomar percurso'), findsNothing);

    await tocar(t, find.text('Voltar ao início'));
    expect(find.text('Comunicação Universal'), findsOneWidget);
  });

  testWidgets('RN11: forma de atendimento já segue as preferências', (t) async {
    await abrirAjuda(t, prefs: const Preferences(textCommunication: true));
    await tocar(t, find.text('Preciso de apoio de um funcionário'));
    await tocar(t, find.text('Revisar pedido'));
    expect(find.text('Mensagem de texto'), findsOneWidget);
  });

  testWidgets('RF41/RF42: cancelar e abrir o cartão durante a espera', (
    t,
  ) async {
    await abrirAjuda(t);
    await tocar(t, find.text('Preciso de acompanhamento'));
    await tocar(t, find.text('Revisar pedido'));
    await tocar(t, find.text('Confirmar e pedir ajuda'));

    await tocar(t, find.text('Cancelar solicitação'));
    expect(find.text('Solicitação cancelada'), findsOneWidget);
    expect(find.text('Novo pedido'), findsOneWidget);

    await tocar(t, find.text('Novo pedido'));
    expect(find.text('O que está acontecendo?'), findsOneWidget);
  });

  testWidgets('Redução de estímulos: cada etapa aparece pronta, sem animar', (
    t,
  ) async {
    await abrirAjuda(t, prefs: const Preferences(calm: true));
    await tocar(t, find.text('Preciso de acompanhamento'));

    // Dois quadros bastam (um para trocar, outro para soltar a etapa
    // antiga): nada fica animando nem duplicado.
    Future<void> tocarSemEsperar(String rotulo) async {
      await t.ensureVisible(find.text(rotulo));
      await t.tap(find.text(rotulo));
      await t.pump();
      await t.pump();
      expect(t.binding.transientCallbackCount, 0, reason: rotulo);
    }

    await tocarSemEsperar('Revisar pedido');
    expect(find.text('Confira seu pedido'), findsOneWidget);
    expect(find.text('O que está acontecendo?'), findsNothing);

    await tocarSemEsperar('Confirmar e pedir ajuda');
    expect(find.text('Acompanhamento'), findsOneWidget);
    expect(find.text('Etapa atual'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tocarSemEsperar('Avançar etapa (demonstração)');
    }
    expect(find.text('Concluída'), findsOneWidget);
    expect(find.text('Etapa atual'), findsOneWidget);
    expect(find.text('Novo pedido'), findsOneWidget);
  });

  testWidgets('Cancelar troca a linha do tempo pelo aviso, sem sobras', (
    t,
  ) async {
    await abrirAjuda(t);
    await tocar(t, find.text('Preciso de acompanhamento'));
    await tocar(t, find.text('Revisar pedido'));
    await tocar(t, find.text('Confirmar e pedir ajuda'));
    await tocar(t, find.text('Avançar etapa (demonstração)'));
    await tocar(t, find.text('Cancelar solicitação'));
    expect(find.text('Solicitação cancelada'), findsOneWidget);
    expect(find.text('Etapa atual'), findsNothing);
    expect(find.text('Atendimento atribuído'), findsNothing);
  });

  testWidgets('RF43: durante o percurso, usa o ponto atual e oferece '
      'retomar', (t) async {
    await nav.abrirDestino(t);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    await nav.tocar(t, find.text('Iniciar navegação'));
    await nav.tocar(t, find.text('Pedir ajuda'));

    expect(find.text('Entrada Principal · Térreo'), findsWidgets);
    await tocar(t, find.text('Não consigo encontrar meu destino'));
    await tocar(t, find.text('Revisar pedido'));
    await tocar(t, find.text('Confirmar e pedir ajuda'));
    for (var i = 0; i < 3; i++) {
      await tocar(t, find.text('Avançar etapa (demonstração)'));
    }
    await tocar(t, find.text('Retomar percurso'));
    expect(
      find.textContaining('Indo para Praça de Alimentação'),
      findsOneWidget,
    );
  });
}
