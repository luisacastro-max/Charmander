import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/models/comunicacao.dart';
import '../welcome_preferences/preferences.dart';
import '../welcome_preferences/preferences_scope.dart';
import 'cartao_ajuda_screen.dart';

/// Mensagens rápidas (RF27): frases prontas por categoria, no idioma do
/// visitante. Tocar numa frase abre o cartão grande para mostrar a outra
/// pessoa (com a tradução para quem lê).
///
/// Com [destaque] (preferência "Mensagens rápidas em destaque"), o bloco
/// ganha a cor do pilar Comunicação e o selo "Em destaque".
class MensagensRapidas extends StatefulWidget {
  const MensagensRapidas({
    super.key,
    required this.categorias,
    required this.visitante,
    required this.destaque,
    required this.aoEscolher,
  });

  final List<CategoriaMensagens> categorias;
  final AppLanguage visitante;
  final bool destaque;
  final ValueChanged<FraseTraduzida> aoEscolher;

  @override
  State<MensagensRapidas> createState() => _MensagensRapidasState();
}

class _MensagensRapidasState extends State<MensagensRapidas> {
  int _categoria = 0;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final motion = Motion.of(context);
    final destaque = widget.destaque && !t.highContrast;
    final fg = destaque ? c.onAccent : c.ink;
    final cat = widget.categorias[_categoria];

    return StickerCard(
      color: destaque ? c.communication : c.surface,
      borderColor: destaque ? c.shadow : c.border,
      shadow: widget.destaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: fg, size: 28),
              const SizedBox(width: AcessaSpacing.xs),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    tr(context, 'Mensagens rápidas'),
                    style: text.titleLarge?.copyWith(color: fg),
                  ),
                ),
              ),
              if (widget.destaque)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AcessaSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: destaque ? c.onAccent : c.communication,
                    borderRadius: BorderRadius.circular(AcessaRadius.pill),
                  ),
                  child: Text(
                    tr(context, 'Em destaque'),
                    style: text.labelLarge?.copyWith(
                      color: destaque ? c.communication : c.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Text(
            tr(context, 'Toque numa frase para mostrar em letras grandes.'),
            style: text.bodyMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          // Categorias numa faixa rolável: não quebra em telas estreitas.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, k) in widget.categorias.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: AcessaSpacing.xs),
                    child: ChoiceChip(
                      label: Text(k.categoria.em(widget.visitante)),
                      selected: i == _categoria,
                      onSelected: (_) => setState(() => _categoria = i),
                      showCheckmark: false,
                      labelStyle: text.titleSmall?.copyWith(
                        color: i == _categoria ? c.onPrimary : c.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: c.primary,
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border, width: 1.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          AnimatedSwitcher(
            duration: motion.d(Motion.base),
            switchInCurve: Motion.enter,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(.06, 0),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_categoria),
              children: [
                for (final f in cat.frases)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AcessaSpacing.xs),
                    child: _Frase(
                      texto: f.em(widget.visitante),
                      onTap: () => widget.aoEscolher(f),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Frase extends StatelessWidget {
  const _Frase({required this.texto, required this.onTap});
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      hint: tr(context, 'Mostra em letras grandes'),
      excludeSemantics: true,
      label: texto,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AcessaRadius.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AcessaRadius.button),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AcessaSpacing.minTouch,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AcessaSpacing.md,
              vertical: AcessaSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AcessaRadius.button),
              border: Border.all(color: c.border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texto,
                    style: text.titleMedium?.copyWith(color: c.ink),
                  ),
                ),
                Icon(Icons.open_in_full, size: 20, color: c.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão flutuante "Mensagens rápidas" para as telas principais. Só
/// aparece com a preferência "Mensagens rápidas em destaque" ligada.
/// Abre o cartão de ajuda com as mensagens no topo.
class BotaoMensagensRapidas extends StatelessWidget {
  const BotaoMensagensRapidas({super.key, this.destino});

  final String? destino;

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.maybeOf(context)?.prefs;
    if (prefs == null || !prefs.quickMessages) return const SizedBox.shrink();
    final c = AcessaTheme.of(context).colors;
    return FloatingActionButton.extended(
      heroTag: 'mensagens-rapidas',
      backgroundColor: c.communication,
      foregroundColor: c.onAccent,
      icon: const Icon(Icons.bolt),
      label: Text(tr(context, 'Mensagens rápidas')),
      onPressed: () =>
          Navigator.of(context)
              .push(acessaRoute<void>(CartaoAjudaScreen(destino: destino))),
    );
  }
}
