import 'package:flutter/material.dart';

import '../../app/i18n/i18n.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/voz/voz.dart';
import '../../core/widgets/sticker_button.dart';
import '../../data/repositories/ocorrencias_repositorio.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/ocorrencia.dart';
import '../../domain/rules/alertas_apresentacao.dart';
import '../../domain/rules/informacao.dart';
import 'alertas_controller.dart';
import 'alertas_visual.dart';

/// Abre o card de detalhes de um alerta (bottom sheet).
Future<void> mostrarDetalhesAlerta(
  BuildContext context,
  String id,
  ShoppingData dados,
) {
  final c = AcessaTheme.of(context).colors;
  final controller = AlertasScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .85,
        ),
        child: DetalhesAlerta(id: id, dados: dados, controller: controller),
      ),
    ),
  );
}

/// Lista os alertas de um grupo de marcadores próximos.
Future<void> mostrarGrupoAlertas(
  BuildContext context,
  List<Ocorrencia> grupo,
  ShoppingData dados,
) async {
  final c = AcessaTheme.of(context).colors;
  final pontos = {for (final p in dados.pontos) p.id: p};
  final escolhido = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: c.surface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AcessaSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AcessaSpacing.lg,
                0,
                AcessaSpacing.lg,
                AcessaSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  tr(ctx, '${grupo.length} alertas neste local'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            for (final o in grupo)
              ListTile(
                minTileHeight: AcessaSpacing.minTouch + 8,
                textColor: c.ink,
                leading: MarcadorAlerta(tipo: o.tipo, tamanho: 32),
                title: Text(tr(ctx, o.tipo.rotulo)),
                subtitle: Text(
                  tr(ctx, 'Perto de: ${nomeDoLocal(o, pontos) ?? '—'}'),
                  style: TextStyle(color: c.inkMuted),
                ),
                onTap: () => Navigator.of(ctx).pop(o.id),
              ),
          ],
        ),
      ),
    ),
  );
  if (escolhido != null && context.mounted) {
    await mostrarDetalhesAlerta(context, escolhido, dados);
  }
}

/// Relato desta sessão que ainda não foi enviado: tentar de novo ou
/// descartar.
Future<void> mostrarEnvioPendente(BuildContext context, EnvioPendente p) {
  final c = AcessaTheme.of(context).colors;
  final controller = AlertasScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) {
          final text = Theme.of(ctx).textTheme;
          final ainda = controller.pendentes.contains(p);
          final falhou = p.estado == EstadoEnvio.falhou;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AcessaSpacing.lg,
              0,
              AcessaSpacing.lg,
              AcessaSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RotuloTipo(tipo: p.nova.tipo, estilo: text.titleLarge),
                const SizedBox(height: AcessaSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    tr(
                      ctx,
                      !ainda
                          ? 'Alerta enviado.'
                          : falhou
                          ? 'Não enviado. ${p.erro ?? ''}'.trim()
                          : 'Enviando…',
                    ),
                    style: text.bodyLarge,
                  ),
                ),
                if (ainda && falhou) ...[
                  const SizedBox(height: AcessaSpacing.md),
                  StickerButton(
                    label: tr(ctx, 'Tentar de novo'),
                    icon: Icons.refresh,
                    onPressed: () => controller.tentarDeNovo(p),
                  ),
                  const SizedBox(height: AcessaSpacing.sm),
                  StickerButton(
                    label: tr(ctx, 'Descartar'),
                    icon: Icons.delete_outline,
                    kind: StickerButtonKind.secondary,
                    onPressed: () {
                      controller.descartar(p);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}

enum _Voto { confirmar, resolver }

/// Card de detalhes: tipo, aviso de que é relato não verificado,
/// descrição, local, andar, horário, situação e os votos
/// "Ainda está aqui" / "Já foi resolvido".
class DetalhesAlerta extends StatefulWidget {
  const DetalhesAlerta({
    super.key,
    required this.id,
    required this.dados,
    required this.controller,
  });

  final String id;
  final ShoppingData dados;
  final AlertasController controller;

  @override
  State<DetalhesAlerta> createState() => _DetalhesAlertaState();
}

class _DetalhesAlertaState extends State<DetalhesAlerta> {
  _Voto? _enviando;
  _Voto? _falhou;
  String? _erro;

  Future<void> _votar(_Voto v) async {
    setState(() {
      _enviando = v;
      _falhou = null;
      _erro = null;
    });
    try {
      if (v == _Voto.confirmar) {
        await widget.controller.confirmar(widget.id);
      } else {
        await widget.controller.marcarResolvida(widget.id);
      }
      if (!mounted) return;
      setState(() => _enviando = null);
      anunciar(
        context,
        v == _Voto.confirmar
            ? 'Obrigado! Você confirmou que o problema continua.'
            : 'Obrigado! Você avisou que o problema foi resolvido.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = null;
        _falhou = v;
        _erro = e is FalhaOcorrencias
            ? e.mensagem
            : 'Não foi possível enviar a resposta.';
      });
      anunciar(context, 'Não foi possível enviar a resposta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final a = widget.controller;
    final o = a.porId(widget.id);
    String t(String pt) => tr(context, pt);
    if (o == null) {
      return Padding(
        padding: const EdgeInsets.all(AcessaSpacing.lg),
        child: Text(t('Este alerta não existe mais.'), style: text.bodyLarge),
      );
    }
    final agora = a.relogio();
    final local = nomeDoLocal(o, {
      for (final p in widget.dados.pontos) p.id: p,
    });
    final sit = a.situacao(o);
    final ativa = sit == SituacaoOcorrencia.ativa;
    final acao = a.acaoLocal(o.id);
    final podeVotar = ativa && acao == null && _enviando == null;

    Widget linha(IconData icone, String rotulo, String valor) => MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AcessaSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 22, color: c.ink),
            const SizedBox(width: AcessaSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$rotulo: ',
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: valor, style: text.bodyLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AcessaSpacing.lg,
        0,
        AcessaSpacing.lg,
        AcessaSpacing.lg,
      ),
      children: [
        Semantics(
          header: true,
          child: RotuloTipo(tipo: o.tipo, estilo: text.headlineSmall),
        ),
        const SizedBox(height: AcessaSpacing.xs),
        Text(
          t(rotuloEfeito(o.tipo)),
          style: text.titleSmall?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AcessaSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AcessaRadius.button),
            border: Border.all(color: c.simulation, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.groups_2_outlined, color: c.simulation),
              const SizedBox(width: AcessaSpacing.sm),
              Expanded(
                child: Text(
                  t('Relato da comunidade, não verificado'),
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        if (o.descricao case final d? when d.trim().isNotEmpty) ...[
          Text(
            '"$d"',
            style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AcessaSpacing.md),
        ],
        linha(Icons.place_outlined, t('Perto de'), local ?? '—'),
        linha(Icons.layers_outlined, t('Andar'), t(exibir(o.piso))),
        linha(Icons.schedule, t('Quando'), t(textoHorario(o, agora))),
        Semantics(
          liveRegion: true,
          child: linha(
            Icons.info_outline,
            t('Situação'),
            t(textoSituacao(o, agora)),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        StickerButton(
          label: t('Ainda está aqui'),
          icon: Icons.check_circle_outline,
          semanticHint: t('Confirma que o problema continua'),
          onPressed: podeVotar ? () => _votar(_Voto.confirmar) : null,
        ),
        const SizedBox(height: AcessaSpacing.sm),
        StickerButton(
          label: t('Já foi resolvido'),
          icon: Icons.task_alt,
          kind: StickerButtonKind.secondary,
          semanticHint: t('Avisa que o problema não está mais lá'),
          onPressed: podeVotar ? () => _votar(_Voto.resolver) : null,
        ),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: AcessaSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_enviando != null)
                  Text(t('Enviando resposta…'), style: text.bodyMedium),
                if (acao != null)
                  Text(
                    t(
                      acao == AcaoLocal.confirmou
                          ? 'Você já confirmou este alerta. Obrigado!'
                          : 'Você já avisou que foi resolvido. Obrigado!',
                    ),
                    style: text.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                if (_falhou case final f?) ...[
                  Text(
                    t(_erro ?? 'Não foi possível enviar a resposta.'),
                    style: text.bodyMedium?.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _votar(f),
                      icon: const Icon(Icons.refresh),
                      label: Text(t('Tentar de novo')),
                      style: TextButton.styleFrom(
                        foregroundColor: c.focus,
                        minimumSize: const Size(48, AcessaSpacing.minTouch),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Text(
          t(
            'Os alertas ajudam a escolher o caminho, mas não garantem a sua '
            'segurança. Siga a sinalização e as orientações do shopping.',
          ),
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}
