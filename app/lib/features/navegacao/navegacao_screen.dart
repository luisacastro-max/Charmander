import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../app/i18n/i18n.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/voz/voz.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/burst.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/ocorrencia.dart';
import '../../domain/rules/alertas_apresentacao.dart';
import '../../domain/rules/informacao.dart';
import '../../domain/rules/ocorrencias.dart';
import '../../domain/rules/rotas.dart';
import '../../domain/rules/viagem.dart';
import '../ajuda/ajuda_screen.dart';
import '../alertas/alertas_controller.dart';
import '../alertas/alertas_visual.dart';
import '../alertas/reportar_alerta_screen.dart';
import '../comunicacao/cartao_ajuda_screen.dart';
import '../comunicacao/mensagens_rapidas.dart';
import '../destino/destino_screen.dart' show criteriosDe;
import '../ultimo_metro/encontrar_screen.dart';
import '../welcome_preferences/preferences_scope.dart';
import 'mapa_interativo.dart';

/// Navegação Viva (T06) com bússola guiada pelo mapa e mapa interativo
/// (MUD-01, Etapa 3b). RF17–RF22, RF48.
///
/// A localização vem de beacons BLE **simulados**: cada toque em
/// "Simular chegada" representa o celular detectar o beacon do próximo
/// ponto. Em paradas intermediárias, a navegação espera o visitante
/// confirmar antes de seguir (como num app de transporte).
///
/// Com "Orientações por áudio" ligado, a voz fala cada instrução quando a
/// navegação começa e a cada passo, avisa troca de piso, paradas e a
/// chegada, no idioma do visitante.
class NavegacaoScreen extends StatefulWidget {
  const NavegacaoScreen({
    super.key,
    required this.viagem,
    required this.dados,
    this.rotaMaisUsada,
  });

  final Viagem viagem;
  final ShoppingData dados;

  /// Rota mais usada, quando a rota adaptada é diferente: aparece no mapa
  /// tracejada, atrás da rota do visitante.
  final Viagem? rotaMaisUsada;

  @override
  State<NavegacaoScreen> createState() => _NavegacaoScreenState();
}

/// Aviso de alerta da comunidade no caminho que falta.
class _AvisoAlerta {
  const _AvisoAlerta({
    required this.alertas,
    required this.bloqueado,
    this.semAlternativa,
  });

  final List<Ocorrencia> alertas;

  /// O caminho que falta passa por trecho bloqueado (sem "Seguir assim").
  final bool bloqueado;

  /// Não existe outro caminho compatível (com o motivo do motor).
  final SemRota? semAlternativa;
}

class _NavegacaoScreenState extends State<NavegacaoScreen> {
  /// Viagem atual (muda quando o visitante recalcula por causa de alerta).
  late Viagem _viagem = widget.viagem;
  late Viagem? _fantasma = widget.rotaMaisUsada;

  late EstadoNavegacao _estado = _pularParadasJaAlcancadas(
    EstadoNavegacao(widget.viagem),
  );

  /// Alertas já mostrados ao visitante (não avisa duas vezes).
  final _conhecidos = <String>{};
  bool _alertasIniciados = false;
  _AvisoAlerta? _aviso;

  /// Resultado do último "Recalcular rota" (ex.: rota não mudou).
  String? _infoRecalculo;
  final _burst = GlobalKey<BurstState>();

  /// Passo já falado ("perna:passo"), para não falar de novo a cada
  /// reconstrução da tela.
  String? _ultimaFala;

  /// Paradas onde o visitante já está não precisam de confirmação na
  /// abertura (ex.: escolheu como 1ª parada o ponto onde já está).
  static EstadoNavegacao _pularParadasJaAlcancadas(EstadoNavegacao s) {
    while (s.aguardandoSeguir && s.rota.etapas.isEmpty && s.perna == 0) {
      s = s.seguir();
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    // Fala a primeira instrução assim que a navegação abre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _falar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ouve os alertas da comunidade: cada mudança chega aqui, sem recarregar.
    final a = AlertasScope.maybeOf(context);
    if (a == null) return;
    final impacto = a.impacto(widget.dados);
    if (!_alertasIniciados) {
      _alertasIniciados = true;
      // Os avisos que já estavam na rota foram mostrados no resumo.
      for (final x in alertasNasEtapas(etapasRestantes(_estado), impacto)) {
        if (!bloqueia(x.ocorrencia.tipo)) _conhecidos.add(x.ocorrencia.id);
      }
    }
    _verificarAlertas(impacto);
  }

  CriteriosRota _criterios() {
    final prefs = PreferencesScope.maybeOf(context)?.prefs;
    final base = prefs == null ? const CriteriosRota() : criteriosDe(prefs);
    return AlertasScope.maybeOf(context)?.aplicar(base, widget.dados) ?? base;
  }

  /// Confere se surgiu alerta no caminho que falta e monta o aviso.
  void _verificarAlertas(ImpactoAlertas impacto) {
    if (_estado.concluida) return;
    final novos = novosAlertasNoCaminho(_estado, impacto, _conhecidos);
    final bloqueado = caminhoBloqueado(_estado, impacto);
    if (novos.isEmpty) {
      // Bloqueio resolvido ou expirado: o aviso some sozinho.
      if (_aviso?.bloqueado == true && !bloqueado) _aviso = null;
      if (!bloqueado || _aviso != null) return;
    }
    _conhecidos.addAll(novos.map((x) => x.ocorrencia.id));
    final noCaminho = <String, Ocorrencia>{
      for (final x in novos) x.ocorrencia.id: x.ocorrencia,
      if (bloqueado)
        for (final x in alertasNasEtapas(etapasRestantes(_estado), impacto))
          if (bloqueia(x.ocorrencia.tipo)) x.ocorrencia.id: x.ocorrencia,
    };
    SemRota? sem;
    if (bloqueado) {
      final r = recalcularDaqui(widget.dados.motor, _estado, _criterios());
      if (r is ViagemImpossivel) sem = r.motivo;
    }
    _aviso = _AvisoAlerta(
      alertas: noCaminho.values.toList(),
      bloqueado: bloqueado,
      semAlternativa: sem,
    );
    _infoRecalculo = null;
    final pontos = {for (final p in widget.dados.pontos) p.id: p};
    final partes = [
      for (final o in noCaminho.values)
        'Alerta da comunidade no seu caminho: ${fraseDoAlerta(o, pontos)}',
      if (sem != null) ...[
        sem.motivo,
        'Não encontramos outro caminho. Você pode pedir ajuda.',
      ] else if (bloqueado)
        'O caminho está bloqueado. Toque em Recalcular rota.',
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anunciarPartes(partes);
    });
  }

  /// Anuncia frases em português (cada uma traduzida) no leitor de tela e,
  /// com "Orientações por áudio", também pela voz.
  void _anunciarPartes(List<String> partes) {
    final prefs = PreferencesScope.maybeOf(context)?.prefs;
    final idioma = idiomaDe(context);
    final texto = partes.map((p) => traduzir(p, idioma)).join(' ');
    SemanticsService.sendAnnouncement(
      View.of(context),
      texto,
      TextDirection.ltr,
    );
    if (prefs != null && prefs.audioGuidance) {
      Voz.instancia.falarNoIdioma(texto, idioma);
    }
  }

  /// "Recalcular rota": do ponto atual até as paradas que faltam, com as
  /// preferências e os alertas ativos.
  void _recalcular() {
    final a = AlertasScope.maybeOf(context);
    final r = recalcularDaqui(widget.dados.motor, _estado, _criterios());
    switch (r) {
      case Viagem():
        final antes = [for (final e in etapasRestantes(_estado)) e.trecho.id];
        final depois = [
          for (final p in r.pernas)
            for (final e in p.etapas) e.trecho.id,
        ];
        if (listEquals(antes, depois)) {
          const info =
              'Não há caminho melhor. A rota continua a mesma; '
              'siga com atenção no trecho com alerta.';
          setState(() {
            _aviso = null;
            _infoRecalculo = info;
          });
          anunciar(context, info);
          return;
        }
        setState(() {
          _viagem = r;
          _fantasma = null;
          _estado = _pularParadasJaAlcancadas(EstadoNavegacao(r));
          _aviso = null;
          _infoRecalculo = 'Rota recalculada para desviar do alerta.';
          _ultimaFala = null;
          if (a != null) {
            for (final x in alertasNaViagem(r, a.impacto(widget.dados))) {
              _conhecidos.add(x.ocorrencia.id);
            }
          }
        });
        anunciar(context, 'Rota recalculada para desviar do alerta.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _falar();
        });
      case ViagemImpossivel():
        final aviso = _aviso;
        setState(() {
          _aviso = _AvisoAlerta(
            alertas: aviso?.alertas ?? const [],
            bloqueado: aviso?.bloqueado ?? true,
            semAlternativa: r.motivo,
          );
        });
        _anunciarPartes([
          r.motivo.motivo,
          'Não encontramos outro caminho. Você pode pedir ajuda.',
        ]);
    }
  }

  void _seguirAssim() {
    setState(() => _aviso = null);
    anunciar(context, 'Tudo bem. A rota continua a mesma.');
  }

  void _pedirAjuda() => Navigator.of(context).push(
    acessaRoute<void>(
      AjudaScreen(
        pontoId: _estado.pontoAtual.id,
        destino: _estado.paradaAtual.nome,
        dados: widget.dados,
        durantePercurso: true,
      ),
    ),
  );

  void _reportar() => Navigator.of(context).push(
    acessaRoute<void>(
      ReportarAlertaScreen(
        dados: widget.dados,
        pontoInicialId: _estado.pontoAtual.id,
      ),
    ),
  );

  /// Alertas ativos no trecho da etapa atual.
  List<Ocorrencia> _alertasDaEtapa() {
    final etapa = _estado.etapaAtual;
    final a = AlertasScope.maybeOf(context);
    if (etapa == null || a == null) return const [];
    return a.impacto(widget.dados).doTrecho(etapa.trecho.id);
  }

  @override
  void dispose() {
    Voz.instancia.parar();
    super.dispose();
  }

  /// Fala a orientação do estado atual (só com "Orientações por áudio"
  /// ligado). Sem [repetir], só fala quando o passo mudou.
  void _falar({String? pisoAntes, bool repetir = false}) {
    final e = _estado;
    final chave = '${e.perna}:${e.passo}';
    if (!repetir && chave == _ultimaFala) return;
    _ultimaFala = chave;
    final prefs = PreferencesScope.maybeOf(context)?.prefs;
    if (prefs == null || !prefs.audioGuidance) return;
    final texto = [
      ...falaDaNavegacao(e, pisoAntes: pisoAntes),
      for (final o in _alertasDaEtapa())
        'Alerta da comunidade neste trecho: ${o.tipo.rotulo}.',
    ].map((p) => traduzir(p, prefs.language)).join(' ');
    Voz.instancia.falarNoIdioma(texto, prefs.language);
  }

  void _repetir() => _falar(repetir: true);

  void _chegar() {
    final pisoAntes = _estado.pontoAtual.piso;
    setState(() => _estado = _estado.chegarAoProximo());
    _falar(pisoAntes: pisoAntes);
    if (_estado.naParada) {
      HapticFeedback.mediumImpact();
      if (_estado.concluida) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _burst.currentState?.play(),
        );
      }
    } else if (_estado.pontoAtual.piso != pisoAntes) {
      HapticFeedback.selectionClick();
    }
  }

  void _seguir() {
    setState(() => _estado = _estado.seguir());
    _falar();
  }

  /// Fecha a navegação pedindo à tela de rota que volte para "Para onde".
  void _novoDestino() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final e = _estado;
    final v = _viagem;
    final varias = v.pernas.length > 1;
    final prefs = PreferencesScope.maybeOf(context)?.prefs;
    final audio = prefs?.audioGuidance ?? false;
    final mensagens = prefs?.quickMessages ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: tr(context, 'Encerrar navegação'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: tr(context, 'Cartão de ajuda'),
            icon: const Icon(Icons.front_hand_outlined),
            onPressed: () => Navigator.of(context).push(
              acessaRoute<void>(CartaoAjudaScreen(destino: e.paradaAtual.nome)),
            ),
          ),
        ],
      ),
      // Mensagens rápidas sempre à mão (só com a preferência ligada).
      floatingActionButton: BotaoMensagensRapidas(destino: e.paradaAtual.nome),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AcessaSpacing.lg,
          0,
          AcessaSpacing.lg,
          // Espaço extra para o botão flutuante não cobrir os botões.
          AcessaSpacing.xl + (mensagens ? 88 : 0),
        ),
        children: [
          // Progresso geral da viagem.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    context,
                    varias
                        ? (e.ultimaPerna
                              ? 'Destino final · ${e.paradaAtual.nome}'
                              : 'Parada ${e.perna + 1} de ${v.pernas.length} · '
                                    '${e.paradaAtual.nome}')
                        : 'Indo para ${e.paradaAtual.nome}',
                  ),
                  style: text.titleMedium?.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AcessaSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AcessaRadius.pill),
                  child: LinearProgressIndicator(
                    value: e.progresso,
                    minHeight: 10,
                    color: c.help,
                    backgroundColor: c.mapLine,
                    semanticsLabel: tr(context, 'Progresso da rota'),
                  ),
                ),
                const SizedBox(height: AcessaSpacing.xs),
                Text(
                  tr(
                    context,
                    e.concluida
                        ? 'Rota concluída'
                        : 'Faltam ${e.restanteM} m · '
                              '${_minutos(e.restanteM)} min · '
                              'chegada às ${_chegada(e.restanteM)}',
                  ),
                  style: text.bodyLarge,
                ),
              ],
            ),
          ),
          if (_aviso case final aviso?) ...[
            const SizedBox(height: AcessaSpacing.md),
            _CartaoAlertaCaminho(
              aviso: aviso,
              dados: widget.dados,
              onRecalcular: _recalcular,
              onSeguirAssim: aviso.bloqueado ? null : _seguirAssim,
              onPedirAjuda: _pedirAjuda,
            ),
          ],
          if (_infoRecalculo case final info?) ...[
            const SizedBox(height: AcessaSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(tr(context, info), style: text.bodyLarge),
            ),
          ],
          const SizedBox(height: AcessaSpacing.md),
          Semantics(
            liveRegion: true,
            child: e.concluida
                ? Burst(
                    key: _burst,
                    color: c.help,
                    child: _CartaoChegada(estado: e, onNovo: _novoDestino),
                  )
                : e.aguardandoSeguir
                ? _CartaoParada(estado: e, onSeguir: _seguir)
                : _CartaoInstrucao(
                    estado: e,
                    alertas: _alertasDaEtapa(),
                    onRepetir: audio ? _repetir : null,
                  ),
          ),
          // Repetir a fala: só aparece com "Orientações por áudio" ligado.
          if (audio) ...[
            const SizedBox(height: AcessaSpacing.sm),
            StickerButton(
              label: tr(context, 'Repetir instrução'),
              icon: Icons.volume_up,
              kind: StickerButtonKind.secondary,
              semanticHint: tr(context, 'Fala de novo a orientação atual'),
              onPressed: _repetir,
            ),
          ],
          const SizedBox(height: AcessaSpacing.md),
          // Só o mapa (a bússola guiada foi retirada a pedido da equipe).
          MapaInterativo(
            dados: widget.dados,
            estado: e,
            rotaMaisUsada: _fantasma,
            altura: (MediaQuery.sizeOf(context).height * .55).clamp(
              320.0,
              560.0,
            ),
          ),
          if (!e.naParada) ...[
            const SizedBox(height: AcessaSpacing.lg),
            StickerButton(
              label: tr(context, 'Simular chegada: ${e.proximoPonto!.nome}'),
              kind: StickerButtonKind.secondary,
              icon: Icons.bluetooth_searching,
              semanticHint: tr(
                context,
                'Representa o celular detectar o beacon '
                '${e.proximoPonto!.beacon}',
              ),
              onPressed: _chegar,
            ),
            const SizedBox(height: AcessaSpacing.sm),
            SimulationNotice(
              text: tr(
                context,
                'Demonstração: no shopping real, o celular detecta o beacon '
                '${e.proximoPonto!.beacon} sozinho ao chegar perto.',
              ),
            ),
          ],
          const SizedBox(height: AcessaSpacing.lg),
          // Ajuda+ durante o percurso, já com o ponto atual (RF43).
          StickerButton(
            label: tr(context, 'Pedir ajuda'),
            icon: Icons.volunteer_activism_outlined,
            kind: StickerButtonKind.secondary,
            semanticHint: tr(
              context,
              'Abre o Ajuda+ com a sua localização atual',
            ),
            onPressed: _pedirAjuda,
          ),
          const SizedBox(height: AcessaSpacing.md),
          StickerButton(
            label: tr(context, 'Reportar problema'),
            icon: Icons.add_alert_outlined,
            kind: StickerButtonKind.secondary,
            semanticHint: tr(
              context,
              'Avisa outras pessoas sobre algo no caminho, a partir de onde '
              'você está',
            ),
            onPressed: _reportar,
          ),
        ],
      ),
    );
  }
}

int _minutos(int metros) => (metros / 50).ceil().clamp(1, 999);

/// Horário previsto de chegada, como no GPS.
String _chegada(int metros) {
  final h = DateTime.now().add(Duration(minutes: _minutos(metros)));
  return '${h.hour.toString().padLeft(2, '0')}:'
      '${h.minute.toString().padLeft(2, '0')}';
}

/// O que a voz diz no estado [e], em português. Cada item é traduzido
/// separadamente na hora de falar (são chaves de `textosNavegacao`).
/// [pisoAntes] é o piso do ponto anterior, para avisar a troca de piso.
List<String> falaDaNavegacao(EstadoNavegacao e, {String? pisoAntes}) {
  if (e.concluida) {
    final d = e.viagem.destinoFinal;
    return ['Você chegou!', 'Você está em ${d.nome}, ${exibir(d.piso)}.'];
  }
  if (e.aguardandoSeguir) {
    final p = e.proximaParada!;
    return [
      'Você chegou à parada ${e.perna + 1}: ${e.paradaAtual.nome}.',
      'Próxima parada: ${p.nome} (${exibir(p.piso)}). '
          'Quando estiver pronto, siga.',
    ];
  }
  final etapa = e.etapaAtual!;
  final virar = curva(e.etapaAnterior, etapa);
  return [
    if (pisoAntes != null && e.pontoAtual.piso != pisoAntes)
      'Você chegou ao ${exibir(e.pontoAtual.piso)}.',
    if (virar != null) '$virar.',
    etapa.instrucao,
  ];
}

IconData _iconeManobra(Manobra m) => switch (m) {
  Manobra.siga || Manobra.frente => Icons.straight,
  Manobra.direita => Icons.turn_right,
  Manobra.esquerda => Icons.turn_left,
  Manobra.retorno => Icons.u_turn_left,
  Manobra.elevador => Icons.elevator_outlined,
  Manobra.escadaRolante => Icons.escalator_outlined,
  Manobra.escada => Icons.stairs_outlined,
  Manobra.rampa => Icons.accessible_forward,
};

/// Instrução da etapa atual no estilo do banner de um GPS: ícone da
/// manobra, distância grande e o que vem depois (RF18).
class _CartaoInstrucao extends StatelessWidget {
  const _CartaoInstrucao({
    required this.estado,
    this.alertas = const [],
    this.onRepetir,
  });
  final EstadoNavegacao estado;

  /// Alertas da comunidade no trecho desta etapa.
  final List<Ocorrencia> alertas;

  /// Tocar no cartão fala a instrução de novo (só com áudio ligado).
  final VoidCallback? onRepetir;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final etapa = estado.etapaAtual!;
    final virar = curva(estado.etapaAnterior, etapa);
    final m = manobra(estado.etapaAnterior, etapa);
    final depois = estado.etapaSeguinte;
    final fg = t.highContrast ? c.ink : c.onAccent;
    final andando = etapa.trecho.trocaPiso == null;
    String t2(String pt) => tr(context, pt);

    return Semantics(
      label: [
        if (virar != null) t2('$virar.'),
        t2(etapa.instrucao),
        t2(
          'Você está em ${estado.pontoAtual.nome}, '
          '${exibir(estado.pontoAtual.piso)}.',
        ),
        for (final o in alertas)
          '${t2('Alerta da comunidade neste trecho: ${o.tipo.rotulo}')}.',
        if (depois != null) t2('Depois: ${depois.instrucao}'),
      ].join(' '),
      onTap: onRepetir,
      onTapHint: onRepetir == null ? null : t2('Toque para ouvir de novo'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onRepetir,
        child: StickerCard(
          color: t.highContrast ? c.surface : c.navigation,
          borderColor: t.highContrast ? c.ink : c.shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: t.highContrast ? c.surface : c.onAccent,
                      borderRadius: BorderRadius.circular(AcessaRadius.button),
                      border: t.highContrast
                          ? Border.all(color: c.ink, width: 2)
                          : null,
                    ),
                    child: Icon(
                      _iconeManobra(m),
                      size: 44,
                      color: t.highContrast ? c.ink : c.navigation,
                    ),
                  ),
                  const SizedBox(width: AcessaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (andando)
                          Text(
                            '${etapa.trecho.distanciaM} m',
                            style: text.displaySmall?.copyWith(color: fg),
                          ),
                        if (virar != null)
                          Text(
                            t2(virar),
                            style: text.titleMedium?.copyWith(color: fg),
                          ),
                      ],
                    ),
                  ),
                  if (onRepetir != null)
                    Icon(Icons.volume_up, size: 26, color: fg),
                ],
              ),
              const SizedBox(height: AcessaSpacing.sm),
              Text(
                t2(etapa.instrucao),
                style: text.headlineSmall?.copyWith(color: fg),
              ),
              for (final o in alertas) ...[
                const SizedBox(height: AcessaSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AcessaSpacing.xs),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(AcessaRadius.button),
                    border: Border.all(color: c.ink, width: 2),
                  ),
                  child: Row(
                    children: [
                      MarcadorAlerta(tipo: o.tipo, tamanho: 30),
                      const SizedBox(width: AcessaSpacing.sm),
                      Expanded(
                        child: Text(
                          t2(
                            'Alerta da comunidade neste trecho: '
                            '${o.tipo.rotulo}',
                          ),
                          style: text.bodyMedium?.copyWith(
                            color: c.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AcessaSpacing.sm),
              Row(
                children: [
                  Icon(Icons.my_location, size: 18, color: fg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t2(
                        'Você está em ${estado.pontoAtual.nome} · '
                        '${exibir(estado.pontoAtual.piso)}',
                      ),
                      style: text.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (depois != null) ...[
                Divider(
                  height: AcessaSpacing.lg,
                  color: fg.withValues(alpha: .4),
                ),
                Row(
                  children: [
                    Text(
                      t2('Depois'),
                      style: text.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AcessaSpacing.sm),
                    Icon(
                      _iconeManobra(manobra(etapa, depois)),
                      size: 22,
                      color: fg,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t2(depois.instrucao),
                        style: text.bodyMedium?.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chegada a uma parada intermediária: espera o visitante seguir.
class _CartaoParada extends StatelessWidget {
  const _CartaoParada({required this.estado, required this.onSeguir});
  final EstadoNavegacao estado;
  final VoidCallback onSeguir;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final prox = estado.proximaParada!;
    return StickerCard(
      color: c.surface,
      borderColor: c.help,
      borderWidth: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: c.help, size: 30),
              const SizedBox(width: AcessaSpacing.sm),
              Expanded(
                child: Text(
                  tr(context, 'Você chegou à parada ${estado.perna + 1}'),
                  style: text.titleMedium?.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Text(estado.paradaAtual.nome, style: text.headlineSmall),
          const SizedBox(height: AcessaSpacing.sm),
          Text(
            tr(
              context,
              'Próxima parada: ${prox.nome} (${exibir(prox.piso)}). '
              'Quando estiver pronto, siga.',
            ),
            style: text.bodyLarge,
          ),
          const SizedBox(height: AcessaSpacing.md),
          StickerButton(
            label: tr(context, 'Seguir para ${prox.nome}'),
            icon: Icons.arrow_forward,
            onPressed: onSeguir,
          ),
        ],
      ),
    );
  }
}

class _CartaoChegada extends StatelessWidget {
  const _CartaoChegada({required this.estado, required this.onNovo});
  final EstadoNavegacao estado;
  final VoidCallback onNovo;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final fg = t.highContrast ? c.ink : c.onAccent;
    final destino = estado.viagem.destinoFinal;
    return StickerCard(
      color: t.highContrast ? c.surface : c.help,
      borderColor: t.highContrast ? c.ink : c.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: fg, size: 30),
              const SizedBox(width: AcessaSpacing.sm),
              Expanded(
                child: Text(
                  tr(context, 'Você chegou!'),
                  style: text.headlineSmall?.copyWith(color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Text(
            '${destino.nome} · ${tr(context, exibir(destino.piso))}',
            style: text.titleMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: AcessaSpacing.md),
          // Último metro: o mapa trouxe até aqui; a câmera acha a porta,
          // o balcão, uma cadeira...
          StickerButton(
            label: tr(context, 'Encontrar com a câmera'),
            icon: Icons.photo_camera_outlined,
            kind: StickerButtonKind.secondary,
            semanticHint: tr(
              context,
              'Ajuda a achar porta, balcão ou cadeira por perto',
            ),
            onPressed: () =>
                Navigator.of(context)
                    .push(acessaRoute<void>(const EncontrarScreen())),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          StickerButton(
            label: tr(context, 'Escolher novo destino'),
            icon: Icons.search,
            onPressed: onNovo,
          ),
        ],
      ),
    );
  }
}

/// Aviso de alerta da comunidade no caminho que falta, com "Recalcular
/// rota" e, só para avisos (não bloqueios), "Seguir assim". Sem rota
/// alternativa, explica e oferece "Pedir ajuda" — nunca sugere escadas.
class _CartaoAlertaCaminho extends StatelessWidget {
  const _CartaoAlertaCaminho({
    required this.aviso,
    required this.dados,
    required this.onRecalcular,
    required this.onSeguirAssim,
    required this.onPedirAjuda,
  });

  final _AvisoAlerta aviso;
  final ShoppingData dados;
  final VoidCallback onRecalcular;
  final VoidCallback? onSeguirAssim;
  final VoidCallback onPedirAjuda;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final pontos = {for (final p in dados.pontos) p.id: p};
    final sem = aviso.semAlternativa;
    String t(String pt) => tr(context, pt);
    return Semantics(
      liveRegion: true,
      container: true,
      child: StickerCard(
        color: c.surface,
        borderColor: aviso.bloqueado ? c.marker : c.simulation,
        borderWidth: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                t(
                  aviso.bloqueado
                      ? 'Caminho bloqueado por alerta da comunidade'
                      : 'Alerta da comunidade no caminho',
                ),
                style: text.titleLarge,
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            for (final o in aviso.alertas)
              Padding(
                padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RotuloTipo(tipo: o.tipo),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(
                          t('Perto de: ${nomeDoLocal(o, pontos) ?? '—'}'),
                          style: text.bodyMedium?.copyWith(color: c.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              t('Relato da comunidade, não verificado'),
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AcessaSpacing.md),
            if (sem != null) ...[
              Text(t(sem.motivo), style: text.titleMedium),
              const SizedBox(height: AcessaSpacing.xs),
              Text(
                t(
                  'Não encontramos outro caminho compatível com as suas '
                  'preferências. Um funcionário do shopping pode ajudar.',
                ),
                style: text.bodyLarge,
              ),
              const SizedBox(height: AcessaSpacing.md),
              StickerButton(
                label: t('Pedir ajuda'),
                icon: Icons.volunteer_activism_outlined,
                semanticHint: t('Abre o Ajuda+ com a sua localização atual'),
                onPressed: onPedirAjuda,
              ),
              const SizedBox(height: AcessaSpacing.sm),
              StickerButton(
                label: t('Tentar recalcular de novo'),
                icon: Icons.refresh,
                kind: StickerButtonKind.secondary,
                onPressed: onRecalcular,
              ),
            ] else ...[
              StickerButton(
                label: t('Recalcular rota'),
                icon: Icons.alt_route,
                semanticHint: t('Procura um caminho que desvie do alerta'),
                onPressed: onRecalcular,
              ),
              if (onSeguirAssim case final seguir?) ...[
                const SizedBox(height: AcessaSpacing.sm),
                StickerButton(
                  label: t('Seguir assim'),
                  icon: Icons.arrow_forward,
                  kind: StickerButtonKind.secondary,
                  semanticHint: t('Mantém a rota atual, com atenção no trecho'),
                  onPressed: seguir,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
