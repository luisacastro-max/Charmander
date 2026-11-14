import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/sticker_button.dart';
import '../../data/shopping_data.dart';
import '../../domain/rules/rotas.dart';
import '../../domain/rules/viagem.dart';
import '../navegacao/mapa_interativo.dart';
import 'alertas_controller.dart';
import 'alertas_estado.dart';
import 'reportar_alerta_screen.dart';

/// Mapa de alertas da comunidade (inspirado no Waze, adaptado à
/// acessibilidade): mostra o que outros visitantes relataram no shopping,
/// atualizado sem recarregar a tela, e permite reportar um problema.
///
/// Os alertas são relatos da comunidade, não verificação oficial.
class MapaAlertasScreen extends StatelessWidget {
  const MapaAlertasScreen({
    super.key,
    required this.dados,
    required this.pontoId,
  });

  final ShoppingData dados;

  /// Onde o visitante está (beacon simulado).
  final String pontoId;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final alertas = AlertasScope.of(context);
    // Rota de um ponto só (origem = destino): o mapa interativo fora de
    // uma rota, em modo exploração.
    final aqui = dados.motor.calcularViagem(pontoId, [
      pontoId,
    ], const CriteriosRota());
    final ativos = alertas.ativas.length;

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AcessaSpacing.lg,
          0,
          AcessaSpacing.lg,
          AcessaSpacing.xl,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              tr(context, 'Mapa de alertas'),
              style: text.displayMedium,
            ),
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Text(
            tr(
              context,
              'Relatos de visitantes sobre o que atrapalha o caminho. '
              'Não são verificados pelo shopping nem garantem a sua segurança.',
            ),
            style: text.bodyLarge?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Semantics(
            liveRegion: true,
            child: Text(
              tr(
                context,
                ativos == 1
                    ? '1 alerta ativo no shopping'
                    : '$ativos alertas ativos no shopping',
              ),
              style: text.titleMedium,
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          StickerButton(
            label: tr(context, 'Reportar problema'),
            icon: Icons.add_alert_outlined,
            semanticHint: tr(
              context,
              'Começa na sua posição atual; você pode ajustar',
            ),
            onPressed: () => Navigator.of(context).push(
              acessaRoute<void>(
                ReportarAlertaScreen(dados: dados, pontoInicialId: pontoId),
              ),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          BannerEstadoAlertas(controller: alertas),
          const SizedBox(height: AcessaSpacing.md),
          FiltroTiposAlerta(controller: alertas),
          const SizedBox(height: AcessaSpacing.md),
          if (aqui is Viagem)
            MapaInterativo(
              dados: dados,
              estado: EstadoNavegacao(aqui),
              exploracao: true,
              altura: (MediaQuery.sizeOf(context).height * .5).clamp(
                300.0,
                520.0,
              ),
            ),
        ],
      ),
    );
  }
}
