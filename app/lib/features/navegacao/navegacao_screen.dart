import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/burst.dart';
import '../../core/widgets/sticker_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/shopping_data.dart';
import '../../domain/rules/informacao.dart';
import '../../domain/rules/viagem.dart';
import '../ajuda/ajuda_screen.dart';
import '../comunicacao/cartao_ajuda_screen.dart';
import '../ultimo_metro/encontrar_screen.dart';
import 'bussola.dart';
import 'mapa_interativo.dart';

enum _Vista { bussola, mapa }

/// Navegação Viva (T06) com bússola guiada pelo mapa e mapa interativo
/// (MUD-01, Etapa 3b). RF17–RF22, RF48.
///
/// A localização vem de beacons BLE **simulados**: cada toque em
/// "Simular chegada" representa o celular detectar o beacon do próximo
/// ponto. Em paradas intermediárias, a navegação espera o visitante
/// confirmar antes de seguir (como num app de transporte).
class NavegacaoScreen extends StatefulWidget {
  const NavegacaoScreen({super.key, required this.viagem, required this.dados});

  final Viagem viagem;
  final ShoppingData dados;

  @override
  State<NavegacaoScreen> createState() => _NavegacaoScreenState();
}

class _NavegacaoScreenState extends State<NavegacaoScreen> {
  late EstadoNavegacao _estado = _pularParadasJaAlcancadas(
    EstadoNavegacao(widget.viagem),
  );
  _Vista _vista = _Vista.bussola;
  final _burst = GlobalKey<BurstState>();

  /// Paradas onde o visitante já está não precisam de confirmação na
  /// abertura (ex.: escolheu como 1ª parada o ponto onde já está).
  static EstadoNavegacao _pularParadasJaAlcancadas(EstadoNavegacao s) {
    while (s.aguardandoSeguir && s.rota.etapas.isEmpty && s.perna == 0) {
      s = s.seguir();
    }
    return s;
  }

  void _chegar() {
    final pisoAntes = _estado.pontoAtual.piso;
    setState(() => _estado = _estado.chegarAoProximo());
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

  void _seguir() => setState(() => _estado = _estado.seguir());

  /// Fecha a navegação pedindo à tela de rota que volte para "Para onde".
  void _novoDestino() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final e = _estado;
    final v = widget.viagem;
    final varias = v.pernas.length > 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: 'Encerrar navegação',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Cartão de ajuda',
            icon: const Icon(Icons.front_hand_outlined),
            onPressed: () => Navigator.of(context).push(
              acessaRoute<void>(CartaoAjudaScreen(destino: e.paradaAtual.nome)),
            ),
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
          // Progresso geral da viagem.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  varias
                      ? (e.ultimaPerna
                            ? 'Destino final · ${e.paradaAtual.nome}'
                            : 'Parada ${e.perna + 1} de ${v.pernas.length} · '
                                  '${e.paradaAtual.nome}')
                      : 'Indo para ${e.paradaAtual.nome}',
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
                    semanticsLabel: 'Progresso da rota',
                  ),
                ),
                const SizedBox(height: AcessaSpacing.xs),
                Text(
                  e.concluida
                      ? 'Rota concluída'
                      : 'Faltam ${e.restanteM} m · '
                            '${_minutos(e.restanteM)} min · '
                            'chegada às ${_chegada(e.restanteM)}',
                  style: text.bodyLarge,
                ),
              ],
            ),
          ),
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
                : _CartaoInstrucao(estado: e),
          ),
          const SizedBox(height: AcessaSpacing.md),
          SegmentedButton<_Vista>(
            segments: const [
              ButtonSegment(
                value: _Vista.bussola,
                label: Text('Bússola'),
                icon: Icon(Icons.explore_outlined),
              ),
              ButtonSegment(
                value: _Vista.mapa,
                label: Text('Mapa'),
                icon: Icon(Icons.map_outlined),
              ),
            ],
            selected: {_vista},
            onSelectionChanged: (s) => setState(() => _vista = s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(
                Size(48, AcessaSpacing.minTouch),
              ),
              textStyle: WidgetStatePropertyAll(text.titleMedium),
              foregroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.ink,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? c.primary : c.surface,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: c.border.withValues(alpha: .6), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AcessaSpacing.md),
          if (_vista == _Vista.bussola)
            Center(child: BussolaGuiada(estado: e))
          else
            MapaInterativo(
              dados: widget.dados,
              estado: e,
              altura: (MediaQuery.sizeOf(context).height * .55).clamp(
                320.0,
                560.0,
              ),
            ),
          if (_vista == _Vista.bussola) ...[
            const SizedBox(height: AcessaSpacing.sm),
            Text(
              'A seta aponta para o próximo ponto no mapa do shopping '
              '(para cima = topo do mapa). Não usa a bússola do celular.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
          ],
          if (!e.naParada) ...[
            const SizedBox(height: AcessaSpacing.lg),
            StickerButton(
              label: 'Simular chegada: ${e.proximoPonto!.nome}',
              kind: StickerButtonKind.secondary,
              icon: Icons.bluetooth_searching,
              semanticHint:
                  'Representa o celular detectar o beacon '
                  '${e.proximoPonto!.beacon}',
              onPressed: _chegar,
            ),
            const SizedBox(height: AcessaSpacing.sm),
            SimulationNotice(
              text:
                  'Demonstração: no shopping real, o celular detecta o beacon '
                  '${e.proximoPonto!.beacon} sozinho ao chegar perto.',
            ),
          ],
          const SizedBox(height: AcessaSpacing.lg),
          // Ajuda+ durante o percurso, já com o ponto atual (RF43).
          StickerButton(
            label: 'Pedir ajuda',
            icon: Icons.volunteer_activism_outlined,
            kind: StickerButtonKind.secondary,
            semanticHint: 'Abre o Ajuda+ com a sua localização atual',
            onPressed: () => Navigator.of(context).push(
              acessaRoute<void>(
                AjudaScreen(
                  pontoId: e.pontoAtual.id,
                  destino: e.paradaAtual.nome,
                  dados: widget.dados,
                  durantePercurso: true,
                ),
              ),
            ),
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
  const _CartaoInstrucao({required this.estado});
  final EstadoNavegacao estado;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final etapa = estado.etapaAtual!;
    final virar = curva(estado.etapaAnterior, etapa);
    final m = manobra(estado.etapaAnterior, etapa);
    final depois = estado.etapaSeguinte;
    final dir = estado.direcao;
    final fg = t.highContrast ? c.ink : c.onAccent;
    final andando = etapa.trecho.trocaPiso == null;

    return Semantics(
      label: [
        if (virar != null) '$virar.',
        etapa.instrucao,
        if (dir != null) 'Seta ${direcaoEmTexto(dir)}.',
        'Você está em ${estado.pontoAtual.nome}, ${exibir(estado.pontoAtual.piso)}.',
        if (depois != null) 'Depois: ${depois.instrucao}',
      ].join(' '),
      excludeSemantics: true,
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
                          virar,
                          style: text.titleMedium?.copyWith(color: fg),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Text(
              etapa.instrucao,
              style: text.headlineSmall?.copyWith(color: fg),
            ),
            const SizedBox(height: AcessaSpacing.sm),
            Row(
              children: [
                Icon(Icons.my_location, size: 18, color: fg),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Você está em ${estado.pontoAtual.nome} · '
                    '${exibir(estado.pontoAtual.piso)}',
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
                    'Depois',
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
                      depois.instrucao,
                      style: text.bodyMedium?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
                  'Você chegou à parada ${estado.perna + 1}',
                  style: text.titleMedium?.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Text(estado.paradaAtual.nome, style: text.headlineSmall),
          const SizedBox(height: AcessaSpacing.sm),
          Text(
            'Próxima parada: ${prox.nome} (${exibir(prox.piso)}). '
            'Quando estiver pronto, siga.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AcessaSpacing.md),
          StickerButton(
            label: 'Seguir para ${prox.nome}',
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
                  'Você chegou!',
                  style: text.headlineSmall?.copyWith(color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcessaSpacing.xs),
          Text(
            '${destino.nome} · ${exibir(destino.piso)}',
            style: text.titleMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: AcessaSpacing.md),
          // Último metro: o mapa trouxe até aqui; a câmera acha a porta,
          // o balcão, uma cadeira...
          StickerButton(
            label: 'Encontrar com a câmera',
            icon: Icons.photo_camera_outlined,
            kind: StickerButtonKind.secondary,
            semanticHint: 'Ajuda a achar porta, balcão ou cadeira por perto',
            onPressed: () =>
                Navigator.of(context)
                    .push(acessaRoute<void>(const EncontrarScreen())),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          StickerButton(
            label: 'Escolher novo destino',
            icon: Icons.search,
            onPressed: onNovo,
          ),
        ],
      ),
    );
  }
}
