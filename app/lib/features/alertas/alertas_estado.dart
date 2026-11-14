import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/models/ocorrencia.dart';
import 'alertas_controller.dart';
import 'alertas_visual.dart';

/// Faixa de estado dos alertas: carregando, erro de conexão (com "Tentar
/// de novo") e, na simulação, o aviso de que nada é compartilhado.
/// Nunca afirma que os alertas são compartilhados quando não são.
class BannerEstadoAlertas extends StatelessWidget {
  const BannerEstadoAlertas({super.key, required this.controller});

  final AlertasController controller;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final a = controller;
    final itens = <Widget>[
      if (a.carregando)
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              // Ícone parado (sem animação infinita): o texto diz o estado.
              Icon(Icons.hourglass_top, color: c.ink, size: 24),
              const SizedBox(width: AcessaSpacing.sm),
              Expanded(
                child: Text(
                  tr(context, 'Carregando alertas da comunidade…'),
                  style: text.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      if (a.erroConexao case final erro?)
        Semantics(
          liveRegion: true,
          child: StickerCard(
            color: c.surface,
            borderColor: c.simulation,
            borderWidth: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi_off, color: c.simulation),
                    const SizedBox(width: AcessaSpacing.sm),
                    Expanded(
                      child: Text(
                        tr(context, 'Sem conexão com os alertas.'),
                        style: text.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AcessaSpacing.xs),
                Text(
                  '${tr(context, erro)} '
                  '${tr(context, 'Os alertas mostrados podem estar desatualizados.')}',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AcessaSpacing.sm),
                OutlinedButton.icon(
                  onPressed: a.reconectar,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr(context, 'Tentar de novo')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.ink,
                    minimumSize: const Size(48, AcessaSpacing.minTouch),
                    side: BorderSide(color: c.border, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (!a.compartilhado)
        SimulationNotice(
          text: tr(context, 'Simulação: os alertas ficam só neste aparelho'),
        ),
    ];
    if (itens.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, w) in itens.indexed) ...[
          if (i > 0) const SizedBox(height: AcessaSpacing.sm),
          w,
        ],
      ],
    );
  }
}

/// Filtro por categoria: um chip por tipo (marcado = aparece no mapa).
/// Fica recolhido para o mapa aparecer logo; o título diz quantos tipos
/// estão visíveis.
class FiltroTiposAlerta extends StatelessWidget {
  const FiltroTiposAlerta({super.key, required this.controller});

  final AlertasController controller;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final a = controller;
    final total = TipoOcorrencia.values.length;
    final visiveis = a.tiposVisiveis.length;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AcessaRadius.button),
        border: Border.all(color: c.border.withValues(alpha: .5), width: 1.5),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          minTileHeight: AcessaSpacing.minTouch + 8,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: c.ink,
          collapsedIconColor: c.ink,
          textColor: c.ink,
          collapsedTextColor: c.ink,
          leading: Icon(Icons.filter_list, color: c.ink),
          title: Text(tr(context, 'Filtrar por tipo'), style: text.titleMedium),
          subtitle: Text(
            tr(
              context,
              a.filtrando
                  ? 'Mostrando $visiveis de $total tipos'
                  : 'Mostrando todos os tipos',
            ),
            style: text.bodyMedium?.copyWith(color: c.inkMuted),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AcessaSpacing.md,
            0,
            AcessaSpacing.md,
            AcessaSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AcessaSpacing.sm,
              runSpacing: AcessaSpacing.sm,
              children: [
                for (final t in TipoOcorrencia.values)
                  FilterChip(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconeDoTipo(t), size: 18, color: c.ink),
                        const SizedBox(width: 6),
                        Flexible(child: Text(tr(context, t.rotulo))),
                      ],
                    ),
                    selected: a.tiposVisiveis.contains(t),
                    onSelected: (_) => a.alternarTipo(t),
                    showCheckmark: true,
                    checkmarkColor: c.ink,
                    selectedColor: c.mapLine,
                    backgroundColor: c.surface,
                    labelStyle: text.labelLarge?.copyWith(color: c.ink),
                    side: BorderSide(
                      color: a.tiposVisiveis.contains(t)
                          ? c.border
                          : c.border.withValues(alpha: .4),
                      width: 1.5,
                    ),
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
            if (a.filtrando)
              Padding(
                padding: const EdgeInsets.only(top: AcessaSpacing.sm),
                child: TextButton(
                  onPressed: a.mostrarTodosOsTipos,
                  style: TextButton.styleFrom(
                    foregroundColor: c.focus,
                    minimumSize: const Size(48, AcessaSpacing.minTouch),
                  ),
                  child: Text(tr(context, 'Mostrar todos')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
