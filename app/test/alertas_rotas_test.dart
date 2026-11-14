// Alertas da comunidade influenciando rotas: recálculo durante a
// navegação, ausência de alternativa (sem sugerir escadas) e alertas
// resolvidos ou expirados deixando de afetar a rota.

import 'package:acessa_plus/app/app.dart';
import 'package:acessa_plus/core/widgets/sticker_button.dart';
import 'package:acessa_plus/data/repositories/simulado_ocorrencias.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/domain/models/ocorrencia.dart';
import 'package:acessa_plus/features/ajuda/ajuda_screen.dart';
import 'package:acessa_plus/features/alertas/alertas_controller.dart';
import 'package:acessa_plus/features/alertas/mapa_alertas_screen.dart';
import 'package:acessa_plus/features/alertas/reportar_alerta_screen.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navegacao_test.dart' as nav;

var agora = DateTime(2026, 11, 14, 10, 0);
DateTime relogio() => agora;

/// Outra pessoa (sessão "b") usando o mesmo servidor.
late AlertasController outra;
late ServidorSimulado servidor;

/// Abre "Para onde?" com os alertas sobre um servidor simulado
/// compartilhado com a sessão [outra].
Future<void> abrirDestino(
  WidgetTester t, {
  Preferences prefs = const Preferences(avoidStairs: true),
  Future<void> Function()? antes,
}) async {
  agora = DateTime(2026, 11, 14, 10, 0);
  t.view.physicalSize = const Size(1080, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  final dados = await t.runAsync(() => ShoppingData.carregar());
  servidor = ServidorSimulado(relogio: relogio);
  outra = AlertasController(
    SimuladoOcorrenciasRepository(servidor, sessao: 'b'),
    relogio: relogio,
  );
  if (antes != null) await antes();
  await t.pumpWidget(
    AcessaApp(
      controller: PreferencesController(prefs),
      dados: dados,
      alertas: AlertasController(
        SimuladoOcorrenciasRepository(servidor, sessao: 'a'),
        relogio: relogio,
      ),
    ),
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Começar'));
  await t.pumpAndSettle();
  await nav.tocar(t, find.text('Continuar'));
}

Future<void> relatar(TipoOcorrencia tipo, double x, double y) async {
  await outra.reportar(
    NovaOcorrencia(
      shoppingId: shoppingDemo,
      tipo: tipo,
      piso: 'Térreo',
      x: x,
      y: y,
    ),
  );
}

/// Elevador do Térreo (único caminho sem escadas até o 2º piso).
Future<void> elevadorParado() =>
    relatar(TipoOcorrencia.elevadorParado, 215, 150);

final botaoComEscada = find.byWidgetPredicate(
  (w) => w is StickerButton && w.label.toLowerCase().contains('escada'),
);

Future<void> encerrar(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  outra.dispose();
}

void main() {
  testWidgets('Navegação: aviso no caminho com "Seguir assim" e bloqueio '
      'com "Recalcular rota"', (t) async {
    await abrirDestino(t);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    await nav.tocar(t, find.text('Iniciar navegação'));
    // Hoje a rota passa pela Praça de Eventos.
    expect(find.textContaining('Praça de Eventos'), findsWidgets);

    // Piso molhado no trecho atual: aviso com as duas opções.
    await relatar(TipoOcorrencia.pisoMolhado, 67, 190);
    await t.pumpAndSettle();
    expect(find.text('Alerta da comunidade no caminho'), findsOneWidget);
    expect(find.text('Recalcular rota'), findsOneWidget);
    expect(find.text('Seguir assim'), findsOneWidget);
    await nav.tocar(t, find.text('Seguir assim'));
    expect(find.text('Alerta da comunidade no caminho'), findsNothing);
    // A instrução da etapa avisa do alerta.
    expect(
      find.text(
        'Alerta da comunidade neste trecho: Piso molhado ou escorregadio',
      ),
      findsOneWidget,
    );

    // Passagem interditada entre a Praça de Eventos e o Corredor Central.
    await relatar(TipoOcorrencia.passagemInterditada, 172, 138);
    await t.pumpAndSettle();
    expect(
      find.text('Caminho bloqueado por alerta da comunidade'),
      findsOneWidget,
    );
    expect(find.text('Passagem interditada'), findsWidgets);
    // Bloqueio não tem "Seguir assim".
    expect(find.text('Seguir assim'), findsNothing);
    await nav.tocar(t, find.text('Recalcular rota'));
    expect(
      find.text('Rota recalculada para desviar do alerta.'),
      findsOneWidget,
    );
    expect(
      find.text('Caminho bloqueado por alerta da comunidade'),
      findsNothing,
    );
    // Novo caminho pelo Corredor Oeste.
    expect(find.textContaining('Corredor Oeste'), findsWidgets);
    await nav.simularAte(t, find.text('Você chegou!'));
    await encerrar(t);
  });

  testWidgets('Sem alternativa: "sem escadas" + elevador fora de serviço '
      'explica, oferece Pedir ajuda e não sugere escada', (t) async {
    await abrirDestino(t);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    await nav.tocar(t, find.text('Iniciar navegação'));

    await elevadorParado();
    await t.pumpAndSettle();
    expect(
      find.text('Caminho bloqueado por alerta da comunidade'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Bloqueado por alerta da comunidade: Elevadores'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Não encontramos outro caminho compatível'),
      findsOneWidget,
    );
    expect(find.text('Seguir assim'), findsNothing);
    expect(find.text('Recalcular rota'), findsNothing);
    expect(find.text('Revisar minhas preferências'), findsNothing);
    expect(botaoComEscada, findsNothing);

    await nav.tocar(t, find.text('Pedir ajuda').first);
    expect(find.byType(AjudaScreen), findsOneWidget);
    await encerrar(t);
  });

  testWidgets('Resumo da rota: bloqueio por alerta sem rota, depois '
      'resolvido e expirado deixam de afetar', (t) async {
    await abrirDestino(t, antes: elevadorParado);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    expect(
      find.textContaining('Bloqueado por alerta da comunidade: Elevadores'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Um alerta da comunidade bloqueia'),
      findsOneWidget,
    );
    expect(find.text('Pedir ajuda'), findsOneWidget);
    expect(find.text('Revisar minhas preferências'), findsNothing);
    expect(botaoComEscada, findsNothing);
    expect(find.text('Iniciar navegação'), findsNothing);

    // Alguém avisa que foi resolvido: a rota volta sem recarregar.
    await outra.marcarResolvida(servidor.lista(shoppingDemo).single.id);
    await t.pumpAndSettle();
    expect(find.text('Iniciar navegação'), findsOneWidget);
    expect(find.text('Usa elevador'), findsOneWidget);

    // Novo relato bloqueia de novo...
    await elevadorParado();
    await t.pumpAndSettle();
    expect(find.text('Iniciar navegação'), findsNothing);

    // ...até expirar (12 h sem confirmação).
    agora = agora.add(const Duration(hours: 12, minutes: 1));
    await t.pump(const Duration(minutes: 1));
    await t.pumpAndSettle();
    expect(find.text('Iniciar navegação'), findsOneWidget);
    await encerrar(t);
  });

  testWidgets('Resumo da rota: desvia de piso molhado e mostra '
      '"Desviamos de"', (t) async {
    await abrirDestino(t, prefs: const Preferences());
    // Obstáculo no trecho Balcão → Praça de Eventos.
    await relatar(TipoOcorrencia.obstaculo, 135, 170);
    await nav.tocar(t, find.text('Praça de Eventos'));
    expect(find.text('Desviamos de:'), findsOneWidget);
    expect(
      find.textContaining('Obstáculo no caminho, perto de'),
      findsOneWidget,
    );
    await encerrar(t);
  });

  testWidgets('Reportar problema durante a navegação começa no ponto atual', (
    t,
  ) async {
    await abrirDestino(t);
    await nav.tocar(t, find.text('Praça de Alimentação'));
    await nav.tocar(t, find.text('Iniciar navegação'));
    await nav.tocar(t, find.text('Reportar problema'));
    expect(find.byType(ReportarAlertaScreen), findsOneWidget);
    expect(find.text('Perto de: Entrada Principal'), findsOneWidget);
    await nav.tocar(t, find.byTooltip('Mover o pino para a direita'));
    await nav.tocar(t, find.text('Rampa bloqueada'));
    await nav.tocar(t, find.text('Enviar alerta'));
    expect(find.text('Alerta enviado. Obrigado!'), findsOneWidget);
    expect(
      servidor.lista(shoppingDemo).single.tipo,
      TipoOcorrencia.rampaBloqueada,
    );
    await encerrar(t);
  });

  testWidgets('"Para onde?" mostra o acesso ao mapa de alertas com a '
      'contagem de ativos', (t) async {
    await abrirDestino(
      t,
      antes: () => relatar(TipoOcorrencia.localCheio, 175, 160),
    );
    expect(
      find.bySemanticsLabel(RegExp('^Mapa de alertas, 1 ativo')),
      findsOneWidget,
    );
    await t.tap(find.text('Alertas'));
    await t.pumpAndSettle();
    expect(find.byType(MapaAlertasScreen), findsOneWidget);
    expect(find.text('1 alerta ativo no shopping'), findsOneWidget);
    expect(find.byKey(const ValueKey('alerta-sim-1')), findsOneWidget);
    await encerrar(t);
  });
}
