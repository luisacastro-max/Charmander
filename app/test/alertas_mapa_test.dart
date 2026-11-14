// Mapa colaborativo de alertas: duas sessões, carregando, erro de envio e
// erro de conexão.

import 'dart:async';

import 'package:acessa_plus/app/theme/app_theme.dart';
import 'package:acessa_plus/data/repositories/ocorrencias_repositorio.dart';
import 'package:acessa_plus/data/repositories/simulado_ocorrencias.dart';
import 'package:acessa_plus/data/shopping_data.dart';
import 'package:acessa_plus/domain/models/ocorrencia.dart';
import 'package:acessa_plus/features/alertas/alertas_controller.dart';
import 'package:acessa_plus/features/alertas/mapa_alertas_screen.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relógio fixo e ajustável (alertas expiram por tempo).
var agora = DateTime(2026, 11, 14, 10, 0);
DateTime relogio() => agora;

/// Um "aparelho": o app com o mapa de alertas aberto, numa sessão própria.
Widget aparelho(
  Key chave,
  AlertasController alertas,
  ShoppingData dados, {
  String pontoId = 'PEV',
}) {
  final prefs = PreferencesController(const Preferences());
  return KeyedSubtree(
    key: chave,
    child: PreferencesScope(
      controller: prefs,
      child: DadosScope(
        dados: dados,
        child: AlertasScope(
          controller: alertas,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(prefs.prefs),
            home: MapaAlertasScreen(dados: dados, pontoId: pontoId),
          ),
        ),
      ),
    ),
  );
}

const chaveA = ValueKey('A');
const chaveB = ValueKey('B');

Finder em(Key chave, Finder f) =>
    find.descendant(of: find.byKey(chave), matching: f);

Future<void> tocarEm(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<ShoppingData> preparar(WidgetTester t, {double largura = 1100}) async {
  agora = DateTime(2026, 11, 14, 10, 0);
  t.view.physicalSize = Size(largura * 2.5, 9000);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  return (await t.runAsync(() => ShoppingData.carregar()))!;
}

AlertasController sessao(ServidorSimulado s, String id) => AlertasController(
  SimuladoOcorrenciasRepository(s, sessao: id),
  relogio: relogio,
)..iniciar();

/// Reporta pelo fluxo da tela: tipo, (posição inicial) e Enviar.
Future<void> reportarPeloFluxo(
  WidgetTester t,
  Key chave,
  String tipo, {
  String? descricao,
}) async {
  await tocarEm(t, em(chave, find.text('Reportar problema')));
  expect(em(chave, find.text('1. O que está acontecendo?')), findsOneWidget);
  // Começa na posição atual do visitante e avisa sobre imprecisão.
  expect(em(chave, find.textContaining('pode ser imprecisa')), findsOneWidget);
  await tocarEm(t, em(chave, find.text(tipo)));
  if (descricao != null) {
    await t.enterText(em(chave, find.byType(TextField)), descricao);
    await t.pumpAndSettle();
  }
  await tocarEm(t, em(chave, find.text('Enviar alerta')));
}

class _RepoControlado implements OcorrenciasRepository {
  /// Como um servidor real: compartilhado entre aparelhos.
  @override
  bool get compartilhado => true;

  StreamController<List<Ocorrencia>> fluxo =
      StreamController<List<Ocorrencia>>.broadcast();
  int assinaturas = 0;

  @override
  Stream<List<Ocorrencia>> observar(String shoppingId) {
    assinaturas++;
    return fluxo.stream;
  }

  @override
  Future<ResultadoRegistro> registrar(NovaOcorrencia nova) =>
      throw const FalhaOcorrencias('Indisponível.');

  @override
  Future<Ocorrencia> confirmar(String id) =>
      throw const FalhaOcorrencias('Indisponível.');

  @override
  Future<Ocorrencia> marcarResolvida(String id) =>
      throw const FalhaOcorrencias('Indisponível.');

  @override
  void fechar() => fluxo.close();
}

void main() {
  testWidgets('Duas sessões: A reporta, B vê sem recarregar, confirma e '
      'resolve; A vê as mudanças', (t) async {
    final dados = await preparar(t, largura: 1100);
    final servidor = ServidorSimulado(relogio: relogio);
    final a = sessao(servidor, 'a');
    final b = sessao(servidor, 'b');
    await t.pumpWidget(
      Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(child: aparelho(chaveA, a, dados)),
          Expanded(child: aparelho(chaveB, b, dados, pontoId: 'ENT_P')),
        ],
      ),
    );
    await t.pumpAndSettle();

    // Simulação: o app não afirma que compartilha.
    expect(
      em(chaveB, find.text('Simulação: os alertas ficam só neste aparelho')),
      findsOneWidget,
    );
    expect(
      em(chaveB, find.text('Nenhum alerta da comunidade neste piso.')),
      findsOneWidget,
    );

    // A reporta piso molhado onde está (Praça de Eventos).
    await reportarPeloFluxo(
      t,
      chaveA,
      'Piso molhado ou escorregadio',
      descricao: 'Poça perto da escada',
    );
    expect(em(chaveA, find.text('Alerta enviado. Obrigado!')), findsOneWidget);
    await tocarEm(t, em(chaveA, find.text('Concluir')));

    // B vê o marcador sem recarregar a tela.
    final marcador = em(chaveB, find.byKey(const ValueKey('alerta-sim-1')));
    expect(marcador, findsOneWidget);
    expect(
      em(chaveB, find.text('1 alerta da comunidade neste piso.')),
      findsOneWidget,
    );
    expect(
      em(
        chaveB,
        find.bySemanticsLabel(
          RegExp('Piso molhado ou escorregadio, perto de Praça de Eventos'),
        ),
      ),
      findsWidgets,
    );

    // A abre os próprios detalhes: não pode votar de novo.
    await tocarEm(t, em(chaveA, find.byKey(const ValueKey('alerta-sim-1'))));
    expect(
      em(chaveA, find.text('Relato da comunidade, não verificado')),
      findsOneWidget,
    );
    expect(
      em(chaveA, find.textContaining('1 confirmação', findRichText: true)),
      findsOneWidget,
    );
    expect(em(chaveA, find.text('"Poça perto da escada"')), findsOneWidget);
    expect(
      em(chaveA, find.text('Você já confirmou este alerta. Obrigado!')),
      findsOneWidget,
    );

    // B toca no marcador, vê os detalhes e confirma.
    await tocarEm(t, marcador);
    expect(
      em(
        chaveB,
        find.textContaining('Perto de: Praça de Eventos', findRichText: true),
      ),
      findsWidgets,
    );
    expect(
      em(chaveB, find.textContaining('Criado às 10:00', findRichText: true)),
      findsOneWidget,
    );
    expect(
      em(chaveB, find.textContaining('vale até 12:00', findRichText: true)),
      findsOneWidget,
    );
    await tocarEm(t, em(chaveB, find.text('Ainda está aqui')));
    expect(
      em(chaveB, find.text('Você já confirmou este alerta. Obrigado!')),
      findsOneWidget,
    );
    // A vê a confirmação de B no card aberto.
    expect(
      em(chaveA, find.textContaining('2 confirmações', findRichText: true)),
      findsOneWidget,
    );
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(560, 10));
    await t.pumpAndSettle();

    // Uma terceira pessoa relata um obstáculo na livraria; B vê, diz que
    // já foi resolvido e o alerta some do mapa de A.
    final c = AlertasController(
      SimuladoOcorrenciasRepository(servidor, sessao: 'c'),
      relogio: relogio,
    );
    await c.reportar(
      const NovaOcorrencia(
        shoppingId: shoppingDemo,
        tipo: TipoOcorrencia.obstaculo,
        piso: 'Térreo',
        x: 330,
        y: 105,
        pontoId: 'LJ4',
      ),
    );
    await t.pumpAndSettle();
    expect(
      em(chaveA, find.text('2 alertas da comunidade neste piso.')),
      findsOneWidget,
    );
    await tocarEm(t, em(chaveB, find.byKey(const ValueKey('alerta-sim-2'))));
    await tocarEm(t, em(chaveB, find.text('Já foi resolvido')));
    expect(
      em(chaveB, find.textContaining('Resolvido', findRichText: true)),
      findsWidgets,
    );
    expect(
      em(chaveA, find.text('1 alerta da comunidade neste piso.')),
      findsOneWidget,
    );
    expect(
      em(chaveA, find.byKey(const ValueKey('alerta-sim-2'))),
      findsNothing,
    );

    await t.pumpWidget(const SizedBox());
    a.dispose();
    b.dispose();
    c.dispose();
  });

  testWidgets('Relato igual a um existente é somado ao alerta', (t) async {
    final dados = await preparar(t, largura: 440);
    final servidor = ServidorSimulado(relogio: relogio);
    final outra = AlertasController(
      SimuladoOcorrenciasRepository(servidor, sessao: 'outra'),
      relogio: relogio,
    );
    await outra.reportar(
      const NovaOcorrencia(
        shoppingId: shoppingDemo,
        tipo: TipoOcorrencia.pisoMolhado,
        piso: 'Térreo',
        x: 175,
        y: 160,
      ),
    );
    final a = sessao(servidor, 'a');
    await t.pumpWidget(aparelho(chaveA, a, dados));
    await t.pumpAndSettle();
    await reportarPeloFluxo(t, chaveA, 'Piso molhado ou escorregadio');
    expect(
      find.text('Somado a um alerta igual que já existia.'),
      findsOneWidget,
    );
    expect(servidor.lista(shoppingDemo), hasLength(1));
    expect(servidor.lista(shoppingDemo).single.confirmacoes, 2);
    await t.pumpWidget(const SizedBox());
    a.dispose();
    outra.dispose();
  });

  testWidgets('Erro de envio: "Tentar de novo", pendente "Não enviado" no '
      'mapa e envio depois', (t) async {
    final dados = await preparar(t, largura: 440);
    final servidor = ServidorSimulado(relogio: relogio)..falharProximas = 2;
    final a = sessao(servidor, 'a');
    await t.pumpWidget(aparelho(chaveA, a, dados));
    await t.pumpAndSettle();

    await reportarPeloFluxo(t, chaveA, 'Obstáculo no caminho');
    expect(find.text('Não foi possível enviar o alerta.'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);
    await tocarEm(t, find.text('Tentar de novo'));
    expect(find.text('Não foi possível enviar o alerta.'), findsOneWidget);

    // Sai sem descartar: o relato aparece no mapa como "Não enviado".
    await tocarEm(t, find.byTooltip('Voltar').last);
    expect(find.text('Não enviado'), findsWidgets);
    expect(find.byKey(const ValueKey('pendente-1')), findsOneWidget);
    await tocarEm(t, find.byKey(const ValueKey('pendente-1')));
    await tocarEm(t, find.text('Tentar de novo'));
    expect(find.text('Alerta enviado.'), findsOneWidget);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('alerta-sim-1')), findsOneWidget);
    expect(find.text('Não enviado'), findsNothing);

    await t.pumpWidget(const SizedBox());
    a.dispose();
  });

  testWidgets('Carregando: mostra o estado; com servidor compartilhado, sem '
      'aviso de simulação', (t) async {
    final dados = await preparar(t, largura: 440);
    final repo = _RepoControlado();
    final a = AlertasController(repo, relogio: relogio)..iniciar();
    await t.pumpWidget(aparelho(chaveA, a, dados));
    await t.pump();
    expect(find.text('Carregando alertas da comunidade…'), findsOneWidget);
    expect(
      find.text('Simulação: os alertas ficam só neste aparelho'),
      findsNothing,
    );
    repo.fluxo.add(const []);
    await t.pumpAndSettle();
    expect(find.text('Carregando alertas da comunidade…'), findsNothing);
    expect(
      find.text('Nenhum alerta da comunidade neste piso.'),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
    a.dispose();
  });

  testWidgets('Erro de conexão: aviso com "Tentar de novo" que reconecta', (
    t,
  ) async {
    final dados = await preparar(t, largura: 440);
    final repo = _RepoControlado();
    final a = AlertasController(repo, relogio: relogio)..iniciar();
    await t.pumpWidget(aparelho(chaveA, a, dados));
    await t.pump();
    repo.fluxo.addError(const FalhaOcorrencias('Servidor fora do ar.'));
    await t.pumpAndSettle();
    expect(find.text('Sem conexão com os alertas.'), findsOneWidget);
    expect(find.textContaining('Servidor fora do ar.'), findsOneWidget);
    expect(repo.assinaturas, 1);

    await tocarEm(t, find.text('Tentar de novo'));
    expect(repo.assinaturas, 2);
    expect(find.text('Carregando alertas da comunidade…'), findsOneWidget);
    repo.fluxo.add([
      Ocorrencia(
        id: 'srv-1',
        shoppingId: shoppingDemo,
        tipo: TipoOcorrencia.localCheio,
        piso: 'Térreo',
        x: 175,
        y: 160,
        criadaEm: agora,
        confirmadaEm: agora,
      ),
    ]);
    await t.pumpAndSettle();
    expect(find.text('Sem conexão com os alertas.'), findsNothing);
    expect(find.byKey(const ValueKey('alerta-srv-1')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    a.dispose();
  });

  testWidgets('Filtro por categoria esconde e mostra os marcadores', (t) async {
    final dados = await preparar(t, largura: 440);
    final servidor = ServidorSimulado(relogio: relogio);
    final a = sessao(servidor, 'a');
    await a.reportar(
      const NovaOcorrencia(
        shoppingId: shoppingDemo,
        tipo: TipoOcorrencia.localCheio,
        piso: 'Térreo',
        x: 175,
        y: 160,
      ),
    );
    await t.pumpWidget(aparelho(chaveA, a, dados));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('alerta-sim-1')), findsOneWidget);
    await tocarEm(t, find.text('Filtrar por tipo'));
    await tocarEm(t, find.widgetWithText(FilterChip, 'Local muito cheio'));
    expect(find.text('Mostrando 7 de 8 tipos'), findsOneWidget);
    expect(find.byKey(const ValueKey('alerta-sim-1')), findsNothing);
    await tocarEm(t, find.text('Mostrar todos'));
    expect(find.byKey(const ValueKey('alerta-sim-1')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    a.dispose();
  });
}
