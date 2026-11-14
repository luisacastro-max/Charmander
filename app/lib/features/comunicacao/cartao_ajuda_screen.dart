import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/burst.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/repositories/json_repositorios.dart';
import '../../data/repositories/repositorios.dart';
import '../../domain/models/comunicacao.dart';
import '../welcome_preferences/preferences.dart';
import '../welcome_preferences/preferences_scope.dart';
import 'cartao_animacoes.dart';

/// Cartão de ajuda: o visitante escolhe uma frase e mostra o celular para
/// outra pessoa (atendente, segurança, outro cliente).
///
/// - A frase aparece grande no idioma de **quem vai ler** e, embaixo,
///   no idioma do visitante, para ele saber o que está mostrando.
/// - "Frente a frente" gira a parte de cima 180°: com o celular sobre a
///   mesa, cada um lê a sua metade.
/// - A outra pessoa responde tocando (Sim, Não, Me siga...). A resposta
///   aparece e é anunciada no idioma do visitante — a conversa funciona
///   nos dois sentidos, inclusive para quem não enxerga ou não ouve.
///
/// Frases traduzidas previamente (assets/data/comunicacao.json), não por
/// tradução automática (RF28).
class CartaoAjudaScreen extends StatefulWidget {
  const CartaoAjudaScreen({super.key, this.destino, this.repositorio});

  /// Preenche "Pode me levar até {destino}?". Sem destino, a frase some.
  final String? destino;
  final ComunicacaoRepository? repositorio;

  @override
  State<CartaoAjudaScreen> createState() => _CartaoAjudaScreenState();
}

class _Dados {
  const _Dados(this.frases, this.respostas);
  final List<FraseTraduzida> frases;
  final List<FraseTraduzida> respostas;
}

class _CartaoAjudaScreenState extends State<CartaoAjudaScreen> {
  late final Future<_Dados> _dados = _carregar();

  /// No Brasil, o mais comum é a outra pessoa falar português.
  AppLanguage _leitor = AppLanguage.pt;

  Future<_Dados> _carregar() async {
    final r = widget.repositorio ?? JsonComunicacaoRepository();
    return _Dados(await r.cartoesAjuda(), await r.respostasRapidas());
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final visitante =
        PreferencesScope.maybeOf(context)?.prefs.language ?? AppLanguage.pt;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Cartão de ajuda'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: FutureBuilder<_Dados>(
        future: _dados,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Não foi possível carregar as frases.'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          final frases = d.frases
              .where((f) => widget.destino != null || !_temDestino(f))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AcessaSpacing.lg,
              0,
              AcessaSpacing.lg,
              AcessaSpacing.xl,
            ),
            children: [
              DistribuirCarta(
                index: 0,
                child: Text('Mostrar para alguém', style: text.headlineMedium),
              ),
              const SizedBox(height: AcessaSpacing.xs),
              DistribuirCarta(
                index: 1,
                child: Text(
                  'Escolha a frase. O celular mostra em letras grandes para a '
                  'outra pessoa ler, e ela pode responder tocando na tela.',
                  style: text.bodyLarge,
                ),
              ),
              const SizedBox(height: AcessaSpacing.md),
              DistribuirCarta(
                index: 2,
                child: Text('Quem vai ler fala', style: text.titleMedium),
              ),
              const SizedBox(height: AcessaSpacing.xs),
              DistribuirCarta(
                index: 3,
                child: _SeletorIdioma(
                  valor: _leitor,
                  aoMudar: (l) => setState(() => _leitor = l),
                ),
              ),
              const SizedBox(height: AcessaSpacing.md),
              // As frases são "distribuídas" como cartas de baralho.
              for (final (i, f) in frases.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
                  child: DistribuirCarta(
                    // Itens lá embaixo (montados ao rolar) não esperam demais.
                    index: i < 8 ? i : 8,
                    atraso: const Duration(milliseconds: 220),
                    estilo: EstiloEntrada.leque,
                    child: _ItemFrase(
                      icone: _icone(f.icone),
                      texto: _preencher(f.em(visitante), widget.destino),
                      onTap: (origem) => Navigator.of(context).push(
                        rotaExpandir<void>(
                          context,
                          _CartaoMostrar(
                            frase: f,
                            respostas: d.respostas,
                            leitorInicial: _leitor,
                            visitante: visitante,
                            destino: widget.destino,
                          ),
                          origem: origem,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AcessaSpacing.sm),
              DistribuirCarta(
                index: frases.length < 9 ? frases.length + 1 : 9,
                atraso: const Duration(milliseconds: 220),
                child: Text(
                  'Traduções feitas previamente, não automáticas.',
                  style: text.bodyMedium?.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _temDestino(FraseTraduzida f) => f.pt.contains('{destino}');

String _preencher(String s, String? destino) =>
    s.replaceAll('{destino}', destino ?? '');

String nomeDoIdioma(AppLanguage l) => switch (l) {
  AppLanguage.pt => 'Português',
  AppLanguage.en => 'English',
  AppLanguage.es => 'Español',
};

IconData _icone(String? chave) => switch (chave) {
  'levar' => Icons.directions_walk,
  'ajuda' => Icons.front_hand_outlined,
  'ler' => Icons.visibility_outlined,
  'escrita' => Icons.edit_note,
  'banheiro' => Icons.wc,
  'elevador' => Icons.elevator_outlined,
  'tranquilo' => Icons.spa_outlined,
  'obrigado' => Icons.favorite_border,
  _ => Icons.chat_bubble_outline,
};

/// Texto anunciado/lido com a pronúncia do idioma certo pelo leitor de tela.
AttributedString _noIdioma(String s, AppLanguage l) => AttributedString(
  s,
  attributes: [
    LocaleStringAttribute(
      range: TextRange(start: 0, end: s.length),
      locale: Locale(l.name),
    ),
  ],
);

class _SeletorIdioma extends StatelessWidget {
  const _SeletorIdioma({
    required this.valor,
    required this.aoMudar,
    this.claro = false,
  });

  final AppLanguage valor;
  final ValueChanged<AppLanguage> aoMudar;

  /// Versão preto no branco, para o cartão grande.
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final fg = claro ? Colors.black : c.ink;
    final sel = claro ? Colors.black : c.primary;
    final onSel = claro ? Colors.white : c.onPrimary;
    final motion = Motion.of(context);
    return Wrap(
      spacing: AcessaSpacing.sm,
      runSpacing: AcessaSpacing.sm,
      children: [
        for (final l in AppLanguage.values)
          // O idioma escolhido "salta" um pouquinho para frente.
          AnimatedScale(
            scale: motion.enabled && l == valor ? 1.08 : 1,
            duration: motion.d(Motion.base),
            curve: Motion.pop,
            child: ChoiceChip(
              label: Text(nomeDoIdioma(l)),
              selected: l == valor,
              onSelected: (_) => aoMudar(l),
              showCheckmark: false,
              labelStyle: text.titleMedium?.copyWith(
                color: l == valor ? onSel : fg,
              ),
              selectedColor: sel,
              backgroundColor: claro ? Colors.white : c.surface,
              side: BorderSide(color: fg, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
      ],
    );
  }
}

class _ItemFrase extends StatelessWidget {
  const _ItemFrase({
    required this.icone,
    required this.texto,
    required this.onTap,
  });

  final IconData icone;
  final String texto;

  /// Recebe o retângulo do item na tela, de onde o cartão "cresce".
  final ValueChanged<Rect?> onTap;

  Rect? _retangulo(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      hint: 'Mostra em letras grandes',
      child: Pressionavel(
        child: InkWell(
          onTap: () => onTap(_retangulo(context)),
          borderRadius: BorderRadius.circular(AcessaRadius.card),
          child: StickerCard(
            shadow: false,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.communication,
                    borderRadius: BorderRadius.circular(AcessaRadius.button),
                  ),
                  child: Icon(icone, color: c.onAccent, size: 28),
                ),
                const SizedBox(width: AcessaSpacing.md),
                Expanded(child: Text(texto, style: text.titleLarge)),
                Icon(Icons.chevron_right, color: c.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O cartão em si: preto no branco, letra enorme, metade de cima para
/// quem lê e metade de baixo para o visitante.
class _CartaoMostrar extends StatefulWidget {
  const _CartaoMostrar({
    required this.frase,
    required this.respostas,
    required this.leitorInicial,
    required this.visitante,
    required this.destino,
  });

  final FraseTraduzida frase;
  final List<FraseTraduzida> respostas;
  final AppLanguage leitorInicial;
  final AppLanguage visitante;
  final String? destino;

  @override
  State<_CartaoMostrar> createState() => _CartaoMostrarState();
}

class _CartaoMostrarState extends State<_CartaoMostrar> {
  late AppLanguage _leitor = widget.leitorInicial;
  bool _frenteAFrente = false;
  FraseTraduzida? _resposta;

  /// Depois da primeira troca de idioma, o destaque da frase grande vem
  /// logo após o "virar" da carta, e não depois da abertura do cartão.
  bool _trocouIdioma = false;

  String _texto(FraseTraduzida f, AppLanguage l) =>
      _preencher(f.em(l), widget.destino);

  void _anunciar(String s) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, s, TextDirection.ltr);
  }

  void _responder(FraseTraduzida r) {
    setState(() => _resposta = r);
    HapticFeedback.heavyImpact();
    _anunciar('Resposta: ${r.em(widget.visitante)}');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    final paraLer = _texto(widget.frase, _leitor);
    final meu = _texto(widget.frase, widget.visitante);
    const preto = Colors.black;

    // Frase grande: ao trocar o idioma, a carta "vira" (gira no eixo
    // horizontal) e a nova frase aparece com o marca-texto passando.
    final chaveFrase = ValueKey(_leitor);
    final fraseGrande = AnimatedSwitcher(
      duration: motion.d(const Duration(milliseconds: 520)),
      switchInCurve: const Interval(.5, 1, curve: Curves.easeOutBack),
      switchOutCurve: const Interval(.5, 1, curve: Curves.easeIn),
      layoutBuilder: _empilharNoTopo,
      transitionBuilder: (child, a) => _virarCarta(child, a, chaveFrase),
      child: Varredura(
        key: chaveFrase,
        atraso: Duration(milliseconds: _trocouIdioma ? 260 : 520),
        child: Semantics(
          attributedLabel: _noIdioma(paraLer, _leitor),
          excludeSemantics: true,
          child: Text(
            paraLer,
            style: text.displaySmall?.copyWith(
              color: preto,
              fontSize: 40,
              height: 1.15,
            ),
          ),
        ),
      ),
    );

    final metadeLeitor = Padding(
      padding: const EdgeInsets.all(AcessaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SeletorIdioma(
            valor: _leitor,
            claro: true,
            aoMudar: (l) => setState(() {
              if (l != _leitor) _trocouIdioma = true;
              _leitor = l;
            }),
          ),
          const SizedBox(height: AcessaSpacing.lg),
          fraseGrande,
          const SizedBox(height: AcessaSpacing.lg),
          Wrap(
            spacing: AcessaSpacing.sm,
            runSpacing: AcessaSpacing.sm,
            children: [
              for (final (i, r) in widget.respostas.indexed)
                // Os botões de resposta entram um a um, com um pulinho.
                DistribuirCarta(
                  index: i,
                  atraso: const Duration(milliseconds: 420),
                  estilo: EstiloEntrada.saltar,
                  child: _BotaoResposta(
                    texto: r.em(_leitor),
                    escolhido: _resposta == r,
                    onPressed: () => _responder(r),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final chaveResposta = ValueKey(_resposta?.id ?? '_aguardando');
    final metadeVisitante = Container(
      color: const Color(0xFFF1F1F1),
      padding: const EdgeInsets.all(AcessaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Você está mostrando:',
            style: text.titleMedium?.copyWith(color: Colors.black87),
          ),
          Text(meu, style: text.titleLarge?.copyWith(color: preto)),
          const SizedBox(height: AcessaSpacing.md),
          Semantics(
            liveRegion: true,
            // A caixa fica amarela devagar, a resposta sobe com um quique
            // e uma faixa de brilho atravessa a caixa.
            child: AnimatedContainer(
              duration: motion.d(Motion.base),
              curve: Motion.enter,
              padding: const EdgeInsets.all(AcessaSpacing.md),
              decoration: BoxDecoration(
                color: _resposta == null ? Colors.white : amareloCartao,
                border: Border.all(color: preto, width: 2),
                borderRadius: BorderRadius.circular(AcessaRadius.button),
              ),
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: motion.d(Motion.slow),
                  layoutBuilder: _empilharNoTopo,
                  transitionBuilder: (child, a) => ExcludeSemantics(
                    excluding: child.key != chaveResposta,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: a,
                        curve: const Interval(0, .5),
                      ),
                      // Sobe passando um pouco do lugar e volta: o quique.
                      child: SlideTransition(
                        position:
                            Tween(
                              begin: const Offset(0, .9),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: a,
                                curve: Curves.elasticOut,
                                reverseCurve: Curves.easeIn,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                  ),
                  child: Varredura(
                    key: chaveResposta,
                    brilho: true,
                    ativo: _resposta != null,
                    atraso: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        _resposta == null
                            ? 'Aguardando resposta…'
                            : 'Resposta: ${_resposta!.em(widget.visitante)}',
                        style: text.headlineSmall?.copyWith(color: preto),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _frenteAFrente = !_frenteAFrente),
                  // O ícone gira junto com a metade de cima.
                  icon: AnimatedRotation(
                    turns: _frenteAFrente ? .5 : 0,
                    duration: motion.d(const Duration(milliseconds: 750)),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(Icons.screen_rotation_alt),
                  ),
                  label: Text(_frenteAFrente ? 'Desvirar' : 'Frente a frente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: preto,
                    side: const BorderSide(color: preto, width: 2),
                    minimumSize: const Size(48, AcessaSpacing.minTouch),
                    textStyle: text.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: AcessaSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Fechar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: preto,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, AcessaSpacing.minTouch),
                    textStyle: text.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // "Frente a frente": a metade de cima gira meia volta, animada.
            MeiaVolta(virado: _frenteAFrente, child: metadeLeitor),
            const Divider(height: 3, thickness: 3, color: preto),
            // A metade do visitante sobe do pé da tela ao abrir.
            DistribuirCarta(
              index: 0,
              atraso: const Duration(milliseconds: 300),
              child: metadeVisitante,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empilha a saída e a entrada alinhadas no topo à esquerda, como o texto
/// fica normalmente (o padrão do AnimatedSwitcher centraliza).
Widget _empilharNoTopo(Widget? atual, List<Widget> anteriores) =>
    Stack(alignment: Alignment.topLeft, children: [...anteriores, ?atual]);

/// "Vira a carta": a frase antiga gira para trás no eixo horizontal e a
/// nova chega girando para frente. Só a frase atual vai para o leitor de
/// tela, para ele não ler as duas durante a troca.
Widget _virarCarta(Widget child, Animation<double> a, Key atual) {
  return ExcludeSemantics(
    excluding: child.key != atual,
    child: AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, child) {
        final v = a.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0015)
              ..rotateX((1 - v) * math.pi / 2),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Botão de resposta: ao tocar, dá um pulinho e solta pontinhos (Burst).
/// A resposta escolhida também fica amarela e aparece em texto embaixo.
class _BotaoResposta extends StatefulWidget {
  const _BotaoResposta({
    required this.texto,
    required this.escolhido,
    required this.onPressed,
  });

  final String texto;
  final bool escolhido;
  final VoidCallback onPressed;

  @override
  State<_BotaoResposta> createState() => _BotaoRespostaState();
}

class _BotaoRespostaState extends State<_BotaoResposta> {
  final _burst = GlobalKey<BurstState>();
  final _pulo = GlobalKey<PulinhoState>();

  void _tocar() {
    _burst.currentState?.play();
    _pulo.currentState?.play();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    const preto = Colors.black;
    return Pulinho(
      key: _pulo,
      child: Burst(
        key: _burst,
        color: rosaComunicacao,
        child: OutlinedButton(
          onPressed: _tocar,
          style: OutlinedButton.styleFrom(
            foregroundColor: preto,
            backgroundColor: widget.escolhido ? amareloCartao : Colors.white,
            side: const BorderSide(color: preto, width: 2),
            minimumSize: const Size(64, AcessaSpacing.minTouch + 8),
            textStyle: text.titleLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AcessaRadius.button),
            ),
          ),
          // Ao trocar o idioma, o rótulo desliza para o novo.
          child: AnimatedSwitcher(
            duration: motion.d(Motion.base),
            switchInCurve: Motion.enter,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, .5),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Text(widget.texto, key: ValueKey(widget.texto)),
          ),
        ),
      ),
    );
  }
}
