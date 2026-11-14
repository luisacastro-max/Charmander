import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/preference_toggle.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/voz/voz.dart';
import '../../core/widgets/sticker_card.dart';
import '../destino/destino_screen.dart';
import 'preferences.dart';
import 'preferences_scope.dart';

/// T02 — Preferências de acessibilidade (RF03, RF04, RF14, RN01, RN02).
///
/// Organizada por necessidade, não por diagnóstico. Texto ampliado,
/// alto contraste e redução de estímulos mudam a tela na hora.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key, this.continuarParaDestino = true});

  /// No primeiro uso, "Continuar" leva a "Para onde você quer ir?".
  /// Quando aberta de outra tela (ex.: revisar rota), só volta.
  final bool continuarParaDestino;

  @override
  Widget build(BuildContext context) {
    final ctrl = PreferencesScope.of(context);
    final p = ctrl.prefs;
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;

    void set(Preferences Function(Preferences) f) => ctrl.update(f);

    var i = 0;
    Widget group(String title, Color accent, List<Widget> items) {
      return Entrance(
        index: i++,
        child: Padding(
          padding: const EdgeInsets.only(top: AcessaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: text.titleLarge),
              ),
              const SizedBox(height: AcessaSpacing.sm),
              for (final it in items) ...[
                it,
                const SizedBox(height: AcessaSpacing.sm),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: tr(context, 'Voltar'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AcessaSpacing.lg,
            0,
            AcessaSpacing.lg,
            AcessaSpacing.xl,
          ),
          children: [
            Entrance(
              index: i++,
              child: Semantics(
                header: true,
                child: Text(
                  tr(context, 'Minha acessibilidade'),
                  style: text.displayMedium,
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Entrance(
              index: i++,
              child: Text(
                tr(
                  context,
                  'Combine o que ajuda você. Não é preciso declarar nenhuma '
                  'deficiência. Dá para mudar quando quiser.',
                ),
                style: text.bodyLarge?.copyWith(color: c.inkMuted),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: i++,
              child: _ActiveCounter(count: p.activeCount),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: i++,
              child: _LivePreview(prefs: p),
            ),
            group(tr(context, 'Ver e ouvir'), c.navigation, [
              PreferenceToggle(
                icon: Icons.text_increase,
                title: tr(context, 'Texto ampliado'),
                description: tr(context, 'Letras maiores em todo o app.'),
                value: p.largeText,
                accent: c.navigation,
                onChanged: (v) => set((p) => p.copyWith(largeText: v)),
              ),
              PreferenceToggle(
                icon: Icons.contrast,
                title: tr(context, 'Alto contraste'),
                description: tr(
                  context,
                  'Fundo preto, texto branco e destaques amarelos.',
                ),
                value: p.highContrast,
                accent: c.navigation,
                revealsTheme: true,
                onChanged: (v) => set((p) => p.copyWith(highContrast: v)),
              ),
              PreferenceToggle(
                icon: Icons.volume_up_outlined,
                title: tr(context, 'Orientações por áudio'),
                description: tr(
                  context,
                  'Instruções faladas durante a navegação.',
                ),
                value: p.audioGuidance,
                accent: c.navigation,
                onChanged: (v) {
                  set((p) => p.copyWith(audioGuidance: v));
                  // Ação explícita: confirma em voz que o áudio ligou.
                  if (v) _falarConfirmacao(p.language, _audioLigado);
                },
              ),
            ]),
            group(tr(context, 'Comunicar'), c.communication, [
              PreferenceToggle(
                icon: Icons.chat_outlined,
                title: tr(context, 'Comunicação por texto'),
                description: tr(
                  context,
                  'A Central abre direto na conversa escrita.',
                ),
                value: p.textCommunication,
                accent: c.communication,
                onChanged: (v) => set((p) => p.copyWith(textCommunication: v)),
              ),
              PreferenceToggle(
                icon: Icons.bolt_outlined,
                title: tr(context, 'Mensagens rápidas em destaque'),
                description: tr(context, 'Frases prontas aparecem primeiro.'),
                value: p.quickMessages,
                accent: c.communication,
                onChanged: (v) => set((p) => p.copyWith(quickMessages: v)),
              ),
            ]),
            group(tr(context, 'Locomover-se'), c.help, [
              // Atalho: só liga os recursos; a escolha não é guardada.
              _ComoVaiCircular(
                onEscolher: () => set(
                  (p) => p.copyWith(avoidStairs: true, preferElevators: true),
                ),
              ),
              PreferenceToggle(
                icon: Icons.accessible_forward,
                title: tr(context, 'Rotas sem escadas'),
                description: tr(context, 'Nenhuma rota passará por degraus.'),
                value: p.avoidStairs,
                accent: c.help,
                onChanged: (v) => set((p) => p.copyWith(avoidStairs: v)),
              ),
              PreferenceToggle(
                icon: Icons.elevator_outlined,
                title: tr(context, 'Preferência por elevadores'),
                description: tr(
                  context,
                  'Elevadores têm prioridade nas trocas de piso.',
                ),
                value: p.preferElevators,
                accent: c.help,
                onChanged: (v) => set((p) => p.copyWith(preferElevators: v)),
              ),
            ]),
            group(tr(context, 'Conforto e clareza'), c.marker, [
              PreferenceToggle(
                icon: Icons.spa_outlined,
                title: tr(context, 'Redução de estímulos'),
                description: tr(
                  context,
                  'Sem animações e com cores mais suaves.',
                ),
                value: p.calm,
                accent: c.marker,
                onChanged: (v) => set((p) => p.copyWith(calm: v)),
              ),
              PreferenceToggle(
                icon: Icons.view_agenda_outlined,
                title: tr(context, 'Navegação simplificada'),
                description: tr(context, 'Menos informações em cada tela.'),
                value: p.simplified,
                accent: c.marker,
                onChanged: (v) => set((p) => p.copyWith(simplified: v)),
              ),
            ]),
            Entrance(
              index: i++,
              child: Padding(
                padding: const EdgeInsets.only(top: AcessaSpacing.lg),
                child: _LanguagePicker(
                  value: p.language,
                  onChanged: (l) {
                    if (l == p.language) return;
                    set((p) => p.copyWith(language: l));
                    // Com áudio ligado, confirma a troca já no novo idioma.
                    if (p.audioGuidance) {
                      _falarConfirmacao(l, 'Idioma: ${_nomeDoIdioma(l)}.');
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.xl),
            Entrance(
              index: i++,
              child: StickerButton(
                label: tr(
                  context,
                  continuarParaDestino ? 'Continuar' : 'Voltar',
                ),
                icon: continuarParaDestino
                    ? Icons.arrow_forward
                    : Icons.arrow_back,
                onPressed: () => continuarParaDestino
                    ? Navigator.of(context)
                          .push(acessaRoute(const DestinoScreen()))
                    : Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: AcessaSpacing.md),
            Entrance(
              index: i++,
              child: StickerButton(
                label: tr(context, 'Apagar minhas preferências'),
                kind: StickerButtonKind.secondary,
                icon: Icons.delete_outline,
                semanticHint: tr(
                  context,
                  'Apaga as escolhas salvas neste aparelho. Pede confirmação.',
                ),
                onPressed: () => _confirmErase(context, ctrl),
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Entrance(
              index: i++,
              child: Text(
                tr(
                  context,
                  'Suas escolhas ficam salvas só neste aparelho. Nada é '
                  'enviado para fora.',
                ),
                style: text.bodyMedium?.copyWith(color: c.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atalho "Como você vai circular hoje?" (RF03, RN01): cada opção só LIGA
/// "Rotas sem escadas" e "Preferência por elevadores", que continuam
/// independentes e podem ser desligados depois. A opção escolhida fica só
/// na memória desta tela: não é salva nem vira preferência (ninguém
/// declara deficiência ou equipamento — RN01, LGPD). Não mexe nas
/// preferências de comunicação (RN02).
class _ComoVaiCircular extends StatefulWidget {
  const _ComoVaiCircular({required this.onEscolher});
  final VoidCallback onEscolher;

  @override
  State<_ComoVaiCircular> createState() => _ComoVaiCircularState();
}

class _ComoVaiCircularState extends State<_ComoVaiCircular> {
  static const _opcoes = [
    (
      Icons.accessible,
      'Sobre rodas',
      'cadeira de rodas, carrinho de bebê, mala',
    ),
    (Icons.assist_walker, 'Com apoio', 'andador, muletas, bengala'),
  ];

  static const _confirmacao =
      'Ativamos "Rotas sem escadas" e "Preferência por elevadores". '
      'Dá para desligar cada um logo abaixo.';

  String? _escolha;

  void _escolher(String opcao) {
    setState(() => _escolha = opcao);
    widget.onEscolher();
    anunciar(context, _confirmacao);
  }

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      color: c.surface,
      borderColor: c.border.withValues(alpha: t.highContrast ? 1 : .35),
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              tr(context, 'Como você vai circular hoje?'),
              style: text.titleMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr(
              context,
              'Atalho: liga os recursos de rota abaixo. '
              'Não guardamos esta escolha.',
            ),
            style: text.bodyMedium?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          for (final (icone, titulo, detalhe) in _opcoes) ...[
            _OpcaoCirculacao(
              icone: icone,
              titulo: tr(context, titulo),
              detalhe: tr(context, detalhe),
              escolhida: _escolha == titulo,
              onTap: () => _escolher(titulo),
            ),
            const SizedBox(height: AcessaSpacing.sm),
          ],
          if (_escolha != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: c.ink, size: 20),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: Text(
                    tr(context, _confirmacao),
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OpcaoCirculacao extends StatelessWidget {
  const _OpcaoCirculacao({
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.escolhida,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String detalhe;
  final bool escolhida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final ativo = escolhida && !t.highContrast;
    final fg = ativo ? c.onAccent : c.ink;
    return Semantics(
      button: true,
      selected: escolhida,
      label: '$titulo: $detalhe',
      hint: tr(context, 'Liga Rotas sem escadas e Preferência por elevadores'),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AcessaRadius.button),
          onTap: onTap,
          child: AnimatedContainer(
            duration: motion.d(Motion.base),
            curve: Motion.enter,
            constraints: const BoxConstraints(
              minHeight: AcessaSpacing.minTouch,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AcessaSpacing.md,
              vertical: AcessaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: ativo ? c.help : c.background,
              borderRadius: BorderRadius.circular(AcessaRadius.button),
              border: Border.all(
                color: escolhida ? c.ink : c.inkMuted,
                width: escolhida ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(icone, color: fg, size: 28),
                const SizedBox(width: AcessaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: text.titleMedium?.copyWith(color: fg),
                      ),
                      Text(
                        detalhe,
                        style: text.bodyMedium?.copyWith(
                          color: ativo ? c.onAccent : c.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (escolhida) Icon(Icons.check, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contador vivo: o número "salta" quando muda e é anunciado por leitores
/// de tela (liveRegion).
class _ActiveCounter extends StatelessWidget {
  const _ActiveCounter({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final label = tr(
      context,
      count == 0
          ? 'Nenhum recurso ativo'
          : count == 1
          ? '1 recurso ativo'
          : '$count recursos ativos',
    );

    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AcessaSpacing.md,
            vertical: AcessaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: c.marker,
            borderRadius: BorderRadius.circular(AcessaRadius.pill),
            border: Border.all(color: c.ink, width: 2),
          ),
          child: AnimatedSwitcher(
            duration: motion.d(Motion.base),
            transitionBuilder: (child, a) => ScaleTransition(
              scale: CurvedAnimation(parent: a, curve: Motion.pop),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Text(
              label,
              key: ValueKey(count),
              style: text.titleMedium?.copyWith(color: c.onMarker),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.value, required this.onChanged});
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    // Cada idioma aparece escrito na própria língua.
    final options = [for (final l in AppLanguage.values) (l, _nomeDoIdioma(l))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(tr(context, 'Idioma'), style: text.titleLarge),
        ),
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          tr(context, 'Muda os textos do app, a voz e as frases prontas.'),
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          children: [
            for (final o in options)
              Semantics(
                selected: value == o.$1,
                inMutuallyExclusiveGroup: true,
                button: true,
                child: ChoiceChip(
                  label: Text(o.$2),
                  selected: value == o.$1,
                  showCheckmark: true,
                  checkmarkColor: c.onPrimary,
                  labelStyle: text.labelLarge?.copyWith(
                    color: value == o.$1 ? c.onPrimary : c.ink,
                  ),
                  selectedColor: c.primary,
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.ink, width: 2),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AcessaSpacing.sm,
                    vertical: AcessaSpacing.sm,
                  ),
                  onSelected: (_) => onChanged(o.$1),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Prévia ao vivo: mostra, em miniatura, como o app fica com as escolhas
/// atuais. Muda na hora a cada interruptor (com transição suave).
class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.prefs});
  final Preferences prefs;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final p = prefs;

    final chips = <(IconData, String, Color)>[
      if (p.avoidStairs)
        (Icons.accessible_forward, 'Sem escadas', c.help)
      else
        (Icons.route_outlined, 'Rota mais curta', c.navigation),
      if (p.preferElevators) (Icons.elevator_outlined, 'Elevador', c.help),
      if (p.audioGuidance)
        (Icons.volume_up_outlined, 'Áudio ligado', c.navigation),
      if (p.quickMessages)
        (Icons.bolt_outlined, 'Frases rápidas', c.communication),
      if (p.calm) (Icons.spa_outlined, 'Sem animações', c.marker),
    ];

    final summary = [
      tr(context, 'Prévia ao vivo.'),
      tr(
        context,
        p.textCommunication
            ? 'A Central abre na conversa escrita.'
            : 'A Central abre nos cartões de comunicação.',
      ),
      ...chips.map((e) => '${tr(context, e.$2)}.'),
    ].join(' ');

    return Semantics(
      container: true,
      liveRegion: false,
      label: summary,
      excludeSemantics: true,
      child: StickerCard(
        color: c.surface,
        borderColor: c.border.withValues(alpha: t.highContrast ? 1 : .3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, color: c.focus, size: 20),
                const SizedBox(width: AcessaSpacing.sm),
                // Flexible: em outros idiomas o título pode ser mais longo.
                Flexible(
                  child: Text(
                    tr(context, 'Prévia ao vivo'),
                    style: text.titleMedium?.copyWith(color: c.focus),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AcessaSpacing.sm),
            AnimatedSwitcher(
              duration: motion.d(Motion.base),
              switchInCurve: Motion.enter,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .08),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: Align(
                key: ValueKey(p.textCommunication),
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AcessaSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.highContrast ? c.surface : c.communication,
                    border: t.highContrast
                        ? Border.all(color: c.ink, width: 2)
                        : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.textCommunication
                            ? Icons.keyboard_outlined
                            : Icons.style_outlined,
                        size: 20,
                        color: t.highContrast ? c.ink : c.onAccent,
                      ),
                      const SizedBox(width: AcessaSpacing.sm),
                      Flexible(
                        child: Text(
                          tr(context, 'Onde fica o banheiro?'),
                          style: text.bodyLarge?.copyWith(
                            color: t.highContrast ? c.ink : c.onAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            AnimatedSize(
              duration: motion.d(Motion.base),
              curve: Motion.enter,
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: AcessaSpacing.sm,
                runSpacing: AcessaSpacing.sm,
                children: [
                  for (final ch in chips)
                    Entrance(
                      key: ValueKey(ch.$2),
                      index: 0,
                      style: EntranceStyle.spin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: t.highContrast ? c.surface : ch.$3,
                          borderRadius: BorderRadius.circular(
                            AcessaRadius.pill,
                          ),
                          border: t.highContrast
                              ? Border.all(color: c.ink, width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ch.$1,
                              size: 18,
                              color: t.highContrast ? c.ink : c.onAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr(context, ch.$2),
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: t.highContrast ? c.ink : c.onAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirma antes de apagar (ação irreversível) e avisa o resultado
/// em texto, que também é lido por leitores de tela.
Future<void> _confirmErase(
  BuildContext context,
  PreferencesController ctrl,
) async {
  final c = AcessaTheme.of(context).colors;
  // O aviso final sai no idioma em uso antes de apagar (depois volta ao
  // padrão, português).
  final idioma = idiomaDe(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      title: Text(
        tr(ctx, 'Apagar suas preferências?'),
        style: Theme.of(ctx).textTheme.titleLarge,
      ),
      content: Text(
        tr(
          ctx,
          'As escolhas salvas neste aparelho serão apagadas e o app volta '
          'ao padrão. Dá para escolher de novo quando quiser.',
        ),
        style: Theme.of(ctx).textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: c.ink,
            minimumSize: const Size(64, AcessaSpacing.minTouch),
          ),
          child: Text(tr(ctx, 'Cancelar')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            minimumSize: const Size(64, AcessaSpacing.minTouch),
          ),
          child: Text(tr(ctx, 'Apagar')),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ctrl.eraseStored();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(traduzir('Preferências apagadas deste aparelho.', idioma)),
    ),
  );
}

const _audioLigado = 'Orientações por áudio ligadas.';

/// Nome do idioma escrito na própria língua (não é traduzido).
String _nomeDoIdioma(AppLanguage l) => switch (l) {
  AppLanguage.pt => 'Português',
  AppLanguage.en => 'English',
  AppLanguage.es => 'Español',
};

/// Confirmação falada de uma escolha feita agora pelo visitante.
/// Sai no [idioma] indicado, mesmo que a tela ainda não tenha sido
/// reconstruída com ele.
void _falarConfirmacao(AppLanguage idioma, String textoPt) {
  Voz.instancia.falarNoIdioma(traduzir(textoPt, idioma), idioma);
}
