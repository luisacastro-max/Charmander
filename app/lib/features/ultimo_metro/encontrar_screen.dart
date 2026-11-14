import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/rules/procura.dart';
import '../comunicacao/cartao_ajuda_screen.dart';
import 'visor_radar.dart';

/// "Último metro": depois de chegar ao destino, a câmera ajuda a achar a
/// porta, o balcão, uma cadeira... (protótipo).
///
/// Dois modos, sempre disponíveis:
/// - **Procurar** (padrão): vibração "quente ou frio" — pulsos lentos
///   quando o alvo não está na imagem, acelerando conforme ele chega ao
///   centro e quase contínuos quando está bem à frente. Funciona em
///   silêncio, só com o tato.
/// - **O que tem aqui?**: descreve tudo o que a câmera vê.
///
/// Gestos na área da câmera (a tela inteira é o botão, sem alvo pequeno):
/// - deslizar para o lado: troca o objeto procurado;
/// - deslizar para cima: "O que tem aqui?";
/// - dois toques ou tocar e segurar: repete onde o alvo está.
///
/// Com leitor de tela (TalkBack/VoiceOver), os mesmos comandos viram ações
/// acessíveis: deslizar para cima/baixo troca o alvo (controle ajustável),
/// tocar duas vezes repete e "O que tem aqui?" fica no menu de ações.
///
/// Movimento: o visor tem radar, ondas no ritmo da vibração e mira que
/// trava no alvo ([VisorRadar]); o título e o aviso trocam deslizando.
/// Tudo isso é enfeite — com movimento reduzido, nada se move.
///
/// **Simulação:** ainda não há câmera nem detector. A cena é fictícia
/// ([cenaDemonstracao]) e o giro do celular é simulado por um controle
/// deslizante. A troca para um detector real (ML Kit/TFLite, no aparelho)
/// só substitui a função [detectar].
class EncontrarScreen extends StatefulWidget {
  const EncontrarScreen({
    super.key,
    this.alvoInicial = Alvo.porta,
    this.cena = cenaDemonstracao,
    this.vibrar = true,
  });

  final Alvo alvoInicial;
  final List<ObjetoCena> cena;

  /// Desligado nos testes de tela para não deixar o relógio de pulsos
  /// rodando.
  final bool vibrar;

  @override
  State<EncontrarScreen> createState() => _EncontrarScreenState();
}

class _EncontrarScreenState extends State<EncontrarScreen> {
  late Alvo _alvo = widget.alvoInicial;
  double _direcao = 0;
  String _aviso = '';
  bool _estavaCentralizado = false;
  Timer? _pulso;

  /// Sentido da última troca de alvo (1 = próximo, -1 = anterior): o
  /// título desliza para o mesmo lado do gesto.
  int _passo = 1;

  List<Deteccao> get _vistos => detectar(widget.cena, _direcao);
  Sinal get _sinal => sinalPara(_alvo, _vistos);

  @override
  void initState() {
    super.initState();
    _aviso = _instrucaoInicial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _anunciar(_aviso));
    if (widget.vibrar) _agendarPulso();
  }

  @override
  void dispose() {
    _pulso?.cancel();
    super.dispose();
  }

  String _instrucaoInicial() =>
      'Procurando: ${_alvo.nome}. Segure o celular na altura do peito e '
      'gire devagar.';

  /// Pulsos re-agendados um a um: o intervalo acompanha o giro.
  void _agendarPulso() {
    _pulso = Timer(_sinal.intervalo, () {
      if (!mounted) return;
      switch (_sinal.forca) {
        case Forca.leve:
          HapticFeedback.lightImpact();
        case Forca.media:
          HapticFeedback.mediumImpact();
        case Forca.forte:
          HapticFeedback.heavyImpact();
      }
      _agendarPulso();
    });
  }

  void _anunciar(String frase) {
    if (!mounted) return;
    setState(() => _aviso = frase);
    SemanticsService.sendAnnouncement(
      View.of(context),
      frase,
      TextDirection.ltr,
    );
  }

  void _girar(double graus) {
    setState(() => _direcao = graus);
    final s = _sinal;
    if (s.centralizado && !_estavaCentralizado) {
      HapticFeedback.heavyImpact();
      _anunciar(descrever(s.deteccao!));
    }
    _estavaCentralizado = s.centralizado;
  }

  void _trocarAlvo(int passo) {
    const todos = Alvo.values;
    final i = (todos.indexOf(_alvo) + passo) % todos.length;
    setState(() {
      _alvo = todos[i];
      _passo = passo.sign;
    });
    HapticFeedback.selectionClick();
    _estavaCentralizado = _sinal.centralizado;
    _anunciar(
      _estavaCentralizado
          ? descrever(_sinal.deteccao!)
          : 'Procurando: ${_alvo.nome}. Gire devagar.',
    );
  }

  void _repetir() {
    final s = _sinal;
    _anunciar(
      s.encontrado
          ? descrever(s.deteccao!)
          : '${_alvo.nome} não está à frente. Continue girando.',
    );
  }

  void _oQueTemAqui() => _anunciar(descreverCena(_vistos));

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final s = _sinal;
    final todos = Alvo.values;
    final anterior = todos[(todos.indexOf(_alvo) - 1) % todos.length];
    final proximo = todos[(todos.indexOf(_alvo) + 1) % todos.length];

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Encontrar com a câmera'),
        leading: IconButton(
          tooltip: 'Fechar câmera',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Cartão de ajuda',
            icon: const Icon(Icons.front_hand_outlined),
            onPressed: () =>
                Navigator.of(context)
                    .push(acessaRoute<void>(const CartaoAjudaScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AcessaSpacing.lg,
          0,
          AcessaSpacing.lg,
          AcessaSpacing.xl,
        ),
        children: [
          // Área da câmera: gestos amplos, sem botão pequeno para achar.
          Entrance(
            index: 0,
            child: Semantics(
              container: true,
              label: 'Área da câmera. Objeto procurado',
              value: _alvo.nome,
              increasedValue: proximo.nome,
              decreasedValue: anterior.nome,
              hint:
                  'Deslize para cima ou para baixo para trocar o objeto. '
                  'Toque duas vezes para saber onde ele está.',
              onIncrease: () => _trocarAlvo(1),
              onDecrease: () => _trocarAlvo(-1),
              onTap: _repetir,
              customSemanticsActions: {
                const CustomSemanticsAction(label: 'O que tem aqui?'):
                    _oQueTemAqui,
              },
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: _repetir,
                onLongPress: _repetir,
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() > 200) _trocarAlvo(v < 0 ? 1 : -1);
                },
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < -200) _oQueTemAqui();
                },
                child: VisorRadar(alvo: _alvo, vistos: _vistos, sinal: s),
              ),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          // O mesmo aviso que o leitor de tela fala, também por escrito.
          Entrance(
            index: 1,
            child: Semantics(
              liveRegion: true,
              child: _CartaoAviso(aviso: _aviso, centralizado: s.centralizado),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          Entrance(
            index: 2,
            child: Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Procurar ${anterior.nome}',
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: AcessaSpacing.minTouch,
                    minHeight: AcessaSpacing.minTouch,
                  ),
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _trocarAlvo(-1),
                ),
                Expanded(
                  child: ClipRect(
                    // O nome novo entra pelo lado do gesto e o antigo sai
                    // pelo outro, como num carrossel.
                    child: AnimatedSwitcher(
                      duration: motion.d(Motion.base),
                      switchInCurve: Motion.enter,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, a) {
                        final entrando = child.key == ValueKey(_alvo);
                        final dx = (entrando ? .45 : -.45) * _passo;
                        return FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: Offset(dx, 0),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        'Procurando: ${_alvo.nome}',
                        key: ValueKey(_alvo),
                        textAlign: TextAlign.center,
                        style: text.headlineSmall,
                      ),
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Procurar ${proximo.nome}',
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: AcessaSpacing.minTouch,
                    minHeight: AcessaSpacing.minTouch,
                  ),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _trocarAlvo(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          Entrance(
            index: 3,
            child: StickerButton(
              label: 'O que tem aqui?',
              icon: Icons.visibility_outlined,
              onPressed: _oQueTemAqui,
            ),
          ),
          const SizedBox(height: AcessaSpacing.lg),
          Entrance(
            index: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Simular giro do celular', style: text.titleMedium),
                Slider(
                  value: _direcao,
                  min: -180,
                  max: 180,
                  divisions: 72,
                  label: '${_direcao.round()}°',
                  semanticFormatterCallback: (v) => '${v.round()} graus',
                  onChanged: _girar,
                ),
              ],
            ),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          const Entrance(
            index: 5,
            child: SimulationNotice(
              text:
                  'Demonstração: a câmera e o reconhecimento de objetos ainda '
                  'são simulados. No aparelho real, basta girar o corpo com o '
                  'celular na mão; a imagem não sai do celular.',
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          Entrance(index: 6, child: _Legenda()),
        ],
      ),
    );
  }
}

/// Cartão com o aviso falado. A frase nova sobe enquanto a antiga some, e
/// o cartão acende em limão com um "pulinho" quando o alvo fica bem à
/// frente.
class _CartaoAviso extends StatelessWidget {
  const _CartaoAviso({required this.aviso, required this.centralizado});

  final String aviso;
  final bool centralizado;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return TweenAnimationBuilder<double>(
      // 0 = procurando, 1 = bem à frente. No caminho, o cartão dá um
      // "pulinho" e a cor acende aos poucos.
      tween: Tween(end: centralizado ? 1 : 0),
      duration: motion.d(Motion.slow),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Transform.scale(
        scale: 1 + .04 * math.sin(math.pi * v),
        child: _cartao(context, v),
      ),
    );
  }

  Widget _cartao(BuildContext context, double v) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    // Sobre o limão (ou o amarelo do alto contraste) o texto é sempre
    // escuro, para manter o contraste acima de 4,5:1.
    final aceso = v >= .5;
    final corTexto = aceso ? c.onAccent : c.ink;

    final cartao = StickerCard(
      color: Color.lerp(c.surface, c.help, v),
      borderColor: aceso && !t.highContrast ? c.shadow : c.border,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: motion.d(Motion.base),
          switchInCurve: Motion.enter,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (atual, anteriores) => Stack(
            alignment: Alignment.topLeft,
            children: [...anteriores, ?atual],
          ),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .35),
                end: Offset.zero,
              ).animate(a),
              child: child,
            ),
          ),
          child: Text(
            aviso,
            key: ValueKey(aviso),
            style: text.titleLarge?.copyWith(color: corTexto),
          ),
        ),
      ),
    );
    // A altura acompanha a frase nova suavemente. Sem movimento, nada de
    // AnimatedSize (com duração zero ele se re-marca durante o layout).
    if (!motion.enabled) return cartao;
    return AnimatedSize(
      duration: Motion.base,
      curve: Motion.enter,
      alignment: Alignment.topCenter,
      child: cartao,
    );
  }
}

class _Legenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const linhas = [
      ('Pulsos lentos e leves', 'o objeto não está na imagem'),
      ('Pulsos acelerando', 'está entrando, continue girando'),
      ('Vibração quase contínua', 'está bem à sua frente'),
      ('Deslizar para o lado', 'troca o objeto procurado'),
      ('Deslizar para cima', 'o que tem aqui?'),
      ('Dois toques', 'repete onde o objeto está'),
    ];
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como usar', style: text.titleLarge),
          const SizedBox(height: AcessaSpacing.sm),
          for (final (gesto, sentido) in linhas)
            Padding(
              padding: const EdgeInsets.only(bottom: AcessaSpacing.xs),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$gesto: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: sentido),
                  ],
                ),
                style: text.bodyLarge,
              ),
            ),
        ],
      ),
    );
  }
}
