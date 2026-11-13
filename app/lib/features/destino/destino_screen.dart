import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/icones.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/shopping.dart';
import '../../domain/rules/informacao.dart';
import '../../domain/rules/rotas.dart';
import '../welcome_preferences/preferences.dart';
import '../welcome_preferences/preferences_scope.dart';
import 'rota_screen.dart';

/// Critérios de rota a partir das preferências (RN02: mobilidade não
/// depende de comunicação). "Redução de estímulos" também evita trechos
/// cadastrados com muito movimento (RN10).
CriteriosRota criteriosDe(Preferences p) => CriteriosRota(
  semEscadas: p.avoidStairs,
  preferirElevador: p.preferElevators,
  caminhoTranquilo: p.calm,
);

/// Atalho grande da tela "Para onde?".
class _Atalho {
  const _Atalho(this.rotulo, this.icone, this.filtro);
  final String rotulo;
  final IconData icone;
  final bool Function(Local) filtro;
}

final _atalhos = <_Atalho>[
  _Atalho('Banheiro', Icons.wc, (l) => l.categoria == 'Banheiros'),
  _Atalho('Banheiro acessível', Icons.accessible, (l) => l.acessivel),
  _Atalho('Elevador', Icons.elevator_outlined, (l) => l.icone == 'elevador'),
  _Atalho('Comer', Icons.restaurant, (l) => l.categoria == 'Alimentação'),
  _Atalho(
    'Saída',
    Icons.logout,
    (l) => l.categoria == 'Saídas' || l.id == 'EST',
  ),
  _Atalho('Espaço tranquilo', Icons.spa_outlined, (l) => l.id == 'ET'),
];

/// Nova tela do fluxo (mudança de escopo aprovada na Etapa 3a):
/// une Explorar (T04) e o início do Planejamento de rota (T05).
/// RF07–RF13, RF15, RF51, RN03, RN04, RNF08.
class DestinoScreen extends StatefulWidget {
  const DestinoScreen({super.key, this.pontoInicial = 'ENT_P'});

  final String pontoInicial;

  @override
  State<DestinoScreen> createState() => _DestinoScreenState();
}

class _DestinoScreenState extends State<DestinoScreen> {
  late String _aqui = widget.pontoInicial;
  final _busca = TextEditingController();
  _Atalho? _atalho;
  String? _piso;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _limpar() => setState(() {
    _busca.clear();
    _atalho = null;
    _piso = null;
  });

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const BrandLogo(size: 20, animate: false),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _dadosProntos(context) != null
          ? _conteudo(context, _dadosProntos(context)!)
          : FutureBuilder<ShoppingData>(
              future: ShoppingData.carregar(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _Mensagem(
                    'Não foi possível carregar o mapa do shopping. '
                    'Peça ajuda no Balcão de Informações.',
                  );
                }
                if (!snap.hasData) {
                  return Center(
                    child: Semantics(
                      label: 'Carregando o mapa do shopping',
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }
                return _conteudo(context, snap.data!);
              },
            ),
    );
  }

  Widget _conteudo(BuildContext context, ShoppingData dados) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final prefs = PreferencesScope.of(context).prefs;
    final criterios = criteriosDe(prefs);
    final aqui = dados.ponto(_aqui);

    final filtrados = dados.locais.where((l) {
      if (!l.destino) return false;
      if (_atalho != null && !_atalho!.filtro(l)) return false;
      if (_piso != null && dados.ponto(l.pontoId).piso != _piso) return false;
      return l.corresponde(_busca.text);
    }).toList();

    // Calcula a rota para cada resultado e ordena: mais perto primeiro;
    // sem rota compatível vai para o fim (nunca escondido).
    final resultados = [
      for (final l in filtrados)
        (l, dados.motor.calcular(_aqui, l.pontoId, criterios)),
    ]..sort((a, b) => _ordem(a.$2).compareTo(_ordem(b.$2)));

    final temFiltro =
        _busca.text.isNotEmpty || _atalho != null || _piso != null;

    var i = 0;
    return ListView(
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
            child: Text('Para onde você quer ir?', style: text.displayMedium),
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: _VoceEstaAqui(
            ponto: aqui,
            onTrocar: () => _escolherPonto(context, dados),
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: TextField(
            controller: _busca,
            onChanged: (_) => setState(() {}),
            style: text.bodyLarge,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar loja ou serviço',
              hintText: 'Ex.: banheiro, pizza, livraria',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busca.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_busca.clear),
                    ),
              filled: true,
              fillColor: c.surface,
              labelStyle: TextStyle(color: c.inkMuted),
              hintStyle: TextStyle(color: c.inkMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AcessaRadius.button),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AcessaRadius.button),
                borderSide: BorderSide(color: c.border.withValues(alpha: .5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AcessaRadius.button),
                borderSide: BorderSide(color: c.focus, width: 3),
              ),
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: _GradeAtalhos(
            selecionado: _atalho,
            onSelecionar: (a) =>
                setState(() => _atalho = _atalho == a ? null : a),
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: _FiltroPiso(
            pisos: dados.pisos,
            selecionado: _piso,
            onSelecionar: (p) => setState(() => _piso = p),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        Entrance(
          index: i++,
          child: _CriteriosAtivos(prefs: prefs),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            resultados.isEmpty
                ? 'Nenhum resultado'
                : '${resultados.length} '
                      '${resultados.length == 1 ? 'resultado' : 'resultados'}'
                      '${temFiltro ? '' : ' · mais perto primeiro'}',
            style: text.titleMedium?.copyWith(color: c.inkMuted),
          ),
        ),
        const SizedBox(height: AcessaSpacing.sm),
        if (resultados.isEmpty)
          _SemResultados(consulta: _busca.text, onLimpar: _limpar)
        else
          for (final (n, (local, rota)) in resultados.indexed) ...[
            Entrance(
              index: n.clamp(0, 6),
              child: _CartaoResultado(
                local: local,
                ponto: dados.ponto(local.pontoId),
                rota: rota,
                onTap: () => Navigator.of(context).push(
                  acessaRoute(
                    RotaScreen(origemId: _aqui, destino: local, dados: dados),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AcessaSpacing.sm),
          ],
      ],
    );
  }

  /// Dados carregados na abertura do app (main.dart), quando disponíveis.
  ShoppingData? _dadosProntos(BuildContext context) =>
      DadosScope.maybeOf(context);

  static int _ordem(ResultadoRota r) => r is Rota ? r.distanciaM : 1 << 30;

  Future<void> _escolherPonto(BuildContext context, ShoppingData dados) async {
    final c = AcessaTheme.of(context).colors;
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
                child: Text(
                  'Simular que estou perto de…',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AcessaSpacing.lg,
                ),
                child: Text(
                  'Na demonstração, escolher um ponto representa o celular '
                  'detectar o beacon BLE daquele lugar.',
                  style: Theme.of(ctx).textTheme.bodyMedium
                      ?.copyWith(color: c.inkMuted),
                ),
              ),
              const SizedBox(height: AcessaSpacing.sm),
              for (final p in dados.pontosSimulaveis)
                ListTile(
                  minTileHeight: AcessaSpacing.minTouch + 8,
                  selected: p.id == _aqui,
                  selectedColor: c.focus,
                  textColor: c.ink,
                  iconColor: c.ink,
                  leading: Icon(
                    p.id == _aqui ? Icons.my_location : Icons.place_outlined,
                  ),
                  title: Text(p.nome),
                  subtitle: Text(
                    '${exibir(p.piso)} · ${p.beacon} (simulado)',
                    style: TextStyle(color: c.inkMuted),
                  ),
                  onTap: () => Navigator.of(ctx).pop(p.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (escolhido != null) setState(() => _aqui = escolhido);
  }
}

class _VoceEstaAqui extends StatelessWidget {
  const _VoceEstaAqui({required this.ponto, required this.onTrocar});
  final PontoReferencia ponto;
  final VoidCallback onTrocar;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      color: c.surface,
      borderColor: c.navigation,
      child: Row(
        children: [
          const _PontoPulsante(),
          const SizedBox(width: AcessaSpacing.md),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Você está aqui',
                    style: text.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                  Text(ponto.nome, style: text.titleMedium),
                  Text(
                    '${exibir(ponto.piso)} · beacon ${ponto.beacon} (simulado)',
                    style: text.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onTrocar,
            style: TextButton.styleFrom(
              foregroundColor: c.focus,
              minimumSize: const Size(48, AcessaSpacing.minTouch),
            ),
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }
}

/// Ponto "você está aqui" que pulsa 3 vezes e para (sem loop infinito).
class _PontoPulsante extends StatefulWidget {
  const _PontoPulsante();

  @override
  State<_PontoPulsante> createState() => _PontoPulsanteState();
}

class _PontoPulsanteState extends State<_PontoPulsante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context).enabled && !_c.isAnimating && _c.value == 0) {
      _c.repeat(count: 3);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.isAnimating ? _c.value : 0.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (v > 0)
                  Container(
                    width: 18 + 26 * v,
                    height: 18 + 26 * v,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.navigation.withValues(alpha: 1 - v),
                        width: 3,
                      ),
                    ),
                  ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: c.navigation,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.ink, width: 3),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GradeAtalhos extends StatelessWidget {
  const _GradeAtalhos({required this.selecionado, required this.onSelecionar});
  final _Atalho? selecionado;
  final ValueChanged<_Atalho> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final cores = [c.navigation, c.help, c.communication];
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - AcessaSpacing.sm) / 2;
        return Wrap(
          spacing: AcessaSpacing.sm,
          runSpacing: AcessaSpacing.sm,
          children: [
            for (final (n, a) in _atalhos.indexed)
              SizedBox(
                width: w,
                child: Semantics(
                  button: true,
                  selected: selecionado == a,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AcessaRadius.button),
                      onTap: () => onSelecionar(a),
                      child: AnimatedContainer(
                        duration: motion.d(Motion.quick),
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: t.highContrast
                              ? c.surface
                              : selecionado == a
                              ? cores[n % 3]
                              : c.surface,
                          borderRadius: BorderRadius.circular(
                            AcessaRadius.button,
                          ),
                          border: Border.all(
                            color: selecionado == a
                                ? (t.highContrast ? c.primary : c.shadow)
                                : cores[n % 3].withValues(alpha: .7),
                            width: selecionado == a ? 3 : 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              a.icone,
                              size: 26,
                              color: selecionado == a && !t.highContrast
                                  ? c.onAccent
                                  : cores[n % 3],
                            ),
                            const SizedBox(width: AcessaSpacing.sm),
                            Expanded(
                              child: Text(
                                a.rotulo,
                                style: text.titleMedium?.copyWith(
                                  color: selecionado == a && !t.highContrast
                                      ? c.onAccent
                                      : c.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FiltroPiso extends StatelessWidget {
  const _FiltroPiso({
    required this.pisos,
    required this.selecionado,
    required this.onSelecionar,
  });
  final List<String> pisos;
  final String? selecionado;
  final ValueChanged<String?> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    Widget chip(String rotulo, String? valor) => Semantics(
      selected: selecionado == valor,
      inMutuallyExclusiveGroup: true,
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado == valor,
        onSelected: (_) => onSelecionar(valor),
        showCheckmark: true,
        checkmarkColor: c.onPrimary,
        selectedColor: c.primary,
        backgroundColor: c.surface,
        labelStyle: text.labelLarge?.copyWith(
          color: selecionado == valor ? c.onPrimary : c.ink,
        ),
        side: BorderSide(color: c.border.withValues(alpha: .6), width: 1.5),
        shape: const StadiumBorder(),
      ),
    );
    return Wrap(
      spacing: AcessaSpacing.sm,
      runSpacing: AcessaSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Piso:', style: text.titleMedium),
        chip('Todos', null),
        for (final p in pisos) chip(p, p),
      ],
    );
  }
}

/// Mostra quais preferências estão influenciando as rotas (transparência).
class _CriteriosAtivos extends StatelessWidget {
  const _CriteriosAtivos({required this.prefs});
  final Preferences prefs;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    final ativos = [
      if (prefs.avoidStairs) 'sem escadas',
      if (prefs.preferElevators) 'prefere elevador',
      if (prefs.calm) 'evita movimento',
    ];
    return Text(
      ativos.isEmpty
          ? 'Rotas pelo caminho mais curto. Para evitar escadas, ative '
                '"Rotas sem escadas" nas preferências.'
          : 'Rotas consideram suas preferências: ${ativos.join(', ')}.',
      style: text.bodyMedium?.copyWith(color: c.inkMuted),
    );
  }
}

class _CartaoResultado extends StatelessWidget {
  const _CartaoResultado({
    required this.local,
    required this.ponto,
    required this.rota,
    required this.onTap,
  });
  final Local local;
  final PontoReferencia ponto;
  final ResultadoRota rota;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final r = rota;
    final distancia = switch (r) {
      Rota(etapas: final e) when e.isEmpty => 'Você já está aqui',
      Rota() => '${r.distanciaM} m · cerca de ${r.minutos} min',
      SemRota(existeComEscada: true) => 'Só há caminho com escadas',
      SemRota() => 'Sem caminho cadastrado',
    };
    final recursos = exibirRecursos(local.recursos);

    return Semantics(
      button: true,
      hint: 'Ver rota',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AcessaRadius.card),
          onTap: onTap,
          child: StickerCard(
            color: c.surface,
            borderColor: c.border.withValues(alpha: t.highContrast ? 1 : .3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.highContrast ? c.surface : c.navigation,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.ink, width: 2),
                  ),
                  child: Icon(
                    iconeDoLocal(local.icone),
                    color: t.highContrast ? c.ink : c.onAccent,
                  ),
                ),
                const SizedBox(width: AcessaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(local.nome, style: text.titleMedium),
                      Text(
                        '${exibir(ponto.piso)} · ${local.categoria}',
                        style: text.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            r is SemRota
                                ? Icons.warning_amber_rounded
                                : Icons.directions_walk,
                            size: 18,
                            color: r is SemRota ? c.simulation : c.help,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              distancia,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recursos.take(2).join(' · '),
                        style: text.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SemResultados extends StatelessWidget {
  const _SemResultados({required this.consulta, required this.onLimpar});
  final String consulta;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      color: c.surface,
      borderColor: c.simulation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consulta.trim().isEmpty
                ? 'Nada encontrado com esses filtros.'
                : 'Nada encontrado para "${consulta.trim()}".',
            style: text.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tente "banheiro", "elevador" ou "comida", ou limpe os filtros.',
            style: text.bodyMedium?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AcessaSpacing.sm),
          TextButton.icon(
            onPressed: onLimpar,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar busca e filtros'),
            style: TextButton.styleFrom(
              foregroundColor: c.focus,
              minimumSize: const Size(48, AcessaSpacing.minTouch),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AcessaSpacing.lg),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
