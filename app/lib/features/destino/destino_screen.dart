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
import '../../domain/rules/viagem.dart';
import '../welcome_preferences/preferences.dart';
import '../welcome_preferences/preferences_scope.dart';
import '../welcome_preferences/preferences_screen.dart';
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
  const DestinoScreen({
    super.key,
    this.pontoInicial = 'ENT_P',
    this.paradaDepoisDe,
  });

  final String pontoInicial;

  /// Modo "adicionar parada" (Etapa 3b): nome da parada anterior. Ao
  /// escolher um local, a tela devolve o [Local] em vez de abrir a rota.
  final String? paradaDepoisDe;

  bool get escolhendoParada => paradaDepoisDe != null;

  @override
  State<DestinoScreen> createState() => _DestinoScreenState();
}

class _DestinoScreenState extends State<DestinoScreen> {
  late String _aqui = widget.pontoInicial;
  final _busca = TextEditingController();
  final _foco = FocusNode();
  _Atalho? _atalho;
  String? _piso;

  /// Paradas escolhidas antes do destino final, como no "+" do Uber.
  final _paradas = <Local>[];

  /// O campo de busca está escolhendo uma parada (e não o destino).
  bool _adicionandoParada = false;
  String _aviso = '';

  @override
  void dispose() {
    _busca.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _limpar() => setState(() {
    _busca.clear();
    _atalho = null;
    _piso = null;
  });

  /// Ponto de onde as distâncias são contadas: a última parada ou onde
  /// o visitante está.
  String get _de => _paradas.isEmpty ? _aqui : _paradas.last.pontoId;

  bool get _podeAdicionar =>
      !widget.escolhendoParada && _paradas.length < maxParadas - 1;

  void _comecarParada() => setState(() {
    _adicionandoParada = true;
    _busca.clear();
    _atalho = null;
    _aviso = 'Escolha a parada ${_paradas.length + 1}.';
    _foco.requestFocus();
  });

  void _removerParada(int i) => setState(() {
    final l = _paradas.removeAt(i);
    _aviso = '${l.nome} removida das paradas.';
  });

  void _escolher(Local local, ShoppingData dados) {
    if (widget.escolhendoParada) {
      Navigator.of(context).pop(local);
      return;
    }
    if (_adicionandoParada) {
      setState(() {
        _paradas.add(local);
        _adicionandoParada = false;
        _busca.clear();
        _atalho = null;
        _aviso =
            '${local.nome} é a parada ${_paradas.length}. '
            'Agora escolha para onde quer ir.';
      });
      return;
    }
    Navigator.of(context).push(
      acessaRoute(
        RotaScreen(
          origemId: _aqui,
          destino: local,
          paradasAntes: List.of(_paradas),
          dados: dados,
        ),
      ),
    );
  }

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
    final de = _de;

    final filtrados = dados.locais.where((l) {
      if (!l.destino) return false;
      // A parada anterior (ou o ponto de partida da busca) não aparece.
      if (widget.escolhendoParada && l.pontoId == widget.pontoInicial) {
        return false;
      }
      if (_paradas.isNotEmpty && l.pontoId == de) return false;
      if (_atalho != null && !_atalho!.filtro(l)) return false;
      if (_piso != null && dados.ponto(l.pontoId).piso != _piso) return false;
      return l.corresponde(_busca.text);
    }).toList();

    // Calcula a rota para cada resultado e ordena: mais perto primeiro;
    // sem rota compatível vai para o fim (nunca escondido).
    final resultados = [
      for (final l in filtrados)
        (l, dados.motor.calcular(de, l.pontoId, criterios)),
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
            child: Text(
              widget.escolhendoParada
                  ? 'Qual a próxima parada?'
                  : 'Para onde você quer ir?',
              style: text.displayMedium,
            ),
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: Wrap(
            spacing: AcessaSpacing.sm,
            runSpacing: AcessaSpacing.sm,
            children: [
              _ChipMenu(
                icone: Icons.layers_outlined,
                rotulo: 'Piso: ${_piso ?? 'Todos'}',
                dica: 'Escolher o piso dos resultados',
                onTap: () => _escolherPiso(context, dados),
              ),
              if (!widget.escolhendoParada)
                _ChipMenu(
                  icone: prefs.avoidStairs
                      ? Icons.accessible_forward
                      : Icons.tune,
                  rotulo: _resumoPreferencias(prefs),
                  dica: 'Revisar minhas preferências de rota',
                  onTap: () => Navigator.of(context).push(
                    acessaRoute(
                      const PreferencesScreen(continuarParaDestino: false),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _CartaoDePara(
                  origem: dados.ponto(_aqui),
                  depoisDe: widget.paradaDepoisDe,
                  paradas: _paradas,
                  busca: _busca,
                  foco: _foco,
                  adicionandoParada: _adicionandoParada,
                  onBusca: () => setState(() {}),
                  onTrocar: () => _escolherPonto(context, dados),
                  onRemoverParada: _removerParada,
                  onCancelarParada: () => setState(() {
                    _adicionandoParada = false;
                    _busca.clear();
                    _aviso = 'Parada cancelada.';
                  }),
                ),
              ),
              if (!widget.escolhendoParada) ...[
                const SizedBox(width: AcessaSpacing.sm),
                Material(
                  color: c.surface,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: c.border.withValues(alpha: .6),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    tooltip: _podeAdicionar
                        ? 'Adicionar parada'
                        : 'Limite de $maxParadas paradas',
                    onPressed: _podeAdicionar && !_adicionandoParada
                        ? _comecarParada
                        : null,
                    icon: const Icon(Icons.add),
                    color: c.ink,
                    disabledColor: c.inkMuted.withValues(alpha: .4),
                    iconSize: 28,
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Semantics(
          liveRegion: true,
          child: _aviso.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AcessaSpacing.sm),
                  child: Text(
                    _aviso,
                    style: text.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                ),
        ),
        const SizedBox(height: AcessaSpacing.md),
        Entrance(
          index: i++,
          child: _PilulasAtalhos(
            selecionado: _atalho,
            onSelecionar: (a) =>
                setState(() => _atalho = _atalho == a ? null : a),
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
        const SizedBox(height: AcessaSpacing.xs),
        if (resultados.isEmpty)
          _SemResultados(consulta: _busca.text, onLimpar: _limpar)
        else
          for (final (n, (local, rota)) in resultados.indexed)
            Entrance(
              index: n.clamp(0, 6),
              child: _LinhaResultado(
                local: local,
                ponto: dados.ponto(local.pontoId),
                rota: rota,
                ultima: n == resultados.length - 1,
                hint: widget.escolhendoParada || _adicionandoParada
                    ? 'Adicionar como parada'
                    : 'Ver rota',
                onTap: () => _escolher(local, dados),
              ),
            ),
      ],
    );
  }

  /// Dados carregados na abertura do app (main.dart), quando disponíveis.
  ShoppingData? _dadosProntos(BuildContext context) =>
      DadosScope.maybeOf(context);

  static int _ordem(ResultadoRota r) => r is Rota ? r.distanciaM : 1 << 30;

  static String _resumoPreferencias(Preferences p) {
    if (p.avoidStairs) return 'Sem escadas';
    if (p.preferElevators) return 'Prefere elevador';
    if (p.calm) return 'Caminho tranquilo';
    return 'Caminho mais curto';
  }

  Future<void> _escolherPiso(BuildContext context, ShoppingData dados) async {
    final c = AcessaTheme.of(context).colors;
    final opcoes = <String?>[null, ...dados.pisos];
    final escolhido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AcessaSpacing.lg,
                0,
                AcessaSpacing.lg,
                AcessaSpacing.sm,
              ),
              child: Text(
                'Mostrar resultados de qual piso?',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            for (final p in opcoes)
              ListTile(
                minTileHeight: AcessaSpacing.minTouch + 8,
                selected: _piso == p,
                selectedColor: c.focus,
                textColor: c.ink,
                iconColor: c.ink,
                leading: Icon(
                  _piso == p
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(p ?? 'Todos os pisos'),
                onTap: () => Navigator.of(ctx).pop(p ?? ''),
              ),
          ],
        ),
      ),
    );
    if (escolhido != null) {
      setState(() => _piso = escolhido.isEmpty ? null : escolhido);
    }
  }

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

/// Chip com seta para baixo (como "Ir agora ▾" e "Para mim ▾" do Uber).
class _ChipMenu extends StatelessWidget {
  const _ChipMenu({
    required this.icone,
    required this.rotulo,
    required this.dica,
    required this.onTap,
  });
  final IconData icone;
  final String rotulo;
  final String dica;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AcessaTheme.of(context).colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      hint: dica,
      child: Material(
        color: c.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AcessaSpacing.minTouch,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 20, color: c.ink),
                  const SizedBox(width: 8),
                  Text(rotulo, style: text.titleSmall?.copyWith(color: c.ink)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: c.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão "de → para" do Uber: ponto de partida (bolinha), paradas e o
/// campo do destino (quadrado), ligados por uma linha.
class _CartaoDePara extends StatelessWidget {
  const _CartaoDePara({
    required this.origem,
    required this.depoisDe,
    required this.paradas,
    required this.busca,
    required this.foco,
    required this.adicionandoParada,
    required this.onBusca,
    required this.onTrocar,
    required this.onRemoverParada,
    required this.onCancelarParada,
  });

  final PontoReferencia origem;
  final String? depoisDe;
  final List<Local> paradas;
  final TextEditingController busca;
  final FocusNode foco;
  final bool adicionandoParada;
  final VoidCallback onBusca;
  final VoidCallback onTrocar;
  final ValueChanged<int> onRemoverParada;
  final VoidCallback onCancelarParada;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;

    Widget trilho(Widget marca, {bool acima = true, bool abaixo = true}) =>
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: acima ? c.inkMuted : Colors.transparent,
                ),
              ),
              marca,
              Expanded(
                child: Container(
                  width: 2,
                  color: abaixo ? c.inkMuted : Colors.transparent,
                ),
              ),
            ],
          ),
        );

    Widget bolinha(Color cor, {double tam = 14}) => Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.background,
        border: Border.all(color: cor, width: 4),
      ),
    );

    final divisor = Divider(
      height: 1,
      indent: 40,
      color: c.border.withValues(alpha: .2),
    );

    final linhas = <Widget>[
      // Origem: onde o visitante está (beacon simulado) ou a parada anterior.
      IntrinsicHeight(
        child: Row(
          children: [
            trilho(bolinha(c.navigation), acima: false),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        depoisDe != null ? 'Depois de' : 'Você está aqui',
                        style: text.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
                      Text(depoisDe ?? origem.nome, style: text.titleMedium),
                      if (depoisDe == null)
                        Text(
                          '${exibir(origem.piso)} · beacon '
                          '${origem.beacon} (simulado)',
                          style: text.bodyMedium?.copyWith(color: c.inkMuted),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (depoisDe == null)
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
      ),
    ];

    for (final (n, p) in paradas.indexed) {
      linhas
        ..add(divisor)
        ..add(
          IntrinsicHeight(
            child: Row(
              children: [
                trilho(
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.help,
                    ),
                    child: Text(
                      '${n + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.onAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parada ${n + 1}',
                          style: text.bodyMedium?.copyWith(color: c.inkMuted),
                        ),
                        Text(p.nome, style: text.titleMedium),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover ${p.nome}',
                  onPressed: () => onRemoverParada(n),
                  icon: const Icon(Icons.close),
                  color: c.inkMuted,
                ),
              ],
            ),
          ),
        );
    }

    // Campo de busca: destino (quadrado) ou parada nova (bolinha).
    linhas
      ..add(divisor)
      ..add(
        IntrinsicHeight(
          child: Row(
            children: [
              trilho(
                adicionandoParada
                    ? bolinha(c.help)
                    : Container(
                        width: 14,
                        height: 14,
                        color: c.ink,
                        alignment: Alignment.center,
                        child: Container(
                          width: 5,
                          height: 5,
                          color: c.background,
                        ),
                      ),
                abaixo: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: busca,
                  focusNode: foco,
                  onChanged: (_) => onBusca(),
                  style: text.titleMedium,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: adicionandoParada
                        ? 'Parada ${paradas.length + 1}'
                        : 'Buscar loja ou serviço',
                    hintText: 'Ex.: banheiro, pizza, livraria',
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: c.inkMuted),
                    hintStyle: TextStyle(color: c.inkMuted),
                    floatingLabelStyle: TextStyle(color: c.focus),
                  ),
                ),
              ),
              if (busca.text.isNotEmpty)
                IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.cancel_outlined),
                  color: c.inkMuted,
                  onPressed: () {
                    busca.clear();
                    onBusca();
                  },
                )
              else if (adicionandoParada)
                IconButton(
                  tooltip: 'Cancelar parada',
                  icon: const Icon(Icons.close),
                  color: c.inkMuted,
                  onPressed: onCancelarParada,
                ),
            ],
          ),
        ),
      );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AcessaRadius.button),
        border: Border.all(
          color: t.highContrast ? c.border : c.ink.withValues(alpha: .85),
          width: 2,
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: linhas),
    );
  }
}

/// Atalhos em pílulas roláveis (alvos de toque de 48 dp).
class _PilulasAtalhos extends StatelessWidget {
  const _PilulasAtalhos({
    required this.selecionado,
    required this.onSelecionar,
  });
  final _Atalho? selecionado;
  final ValueChanged<_Atalho> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final cores = [c.navigation, c.help, c.communication];
    return Wrap(
      spacing: AcessaSpacing.sm,
      runSpacing: AcessaSpacing.sm,
      children: [
        for (final (n, a) in _atalhos.indexed)
          Semantics(
            button: true,
            selected: selecionado == a,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelecionar(a),
                child: AnimatedContainer(
                  duration: motion.d(Motion.quick),
                  constraints: const BoxConstraints(
                    minHeight: AcessaSpacing.minTouch,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: ShapeDecoration(
                    color: selecionado == a && !t.highContrast
                        ? cores[n % 3]
                        : c.surface,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selecionado == a
                            ? (t.highContrast ? c.primary : c.shadow)
                            : cores[n % 3].withValues(alpha: .7),
                        width: selecionado == a ? 3 : 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        a.icone,
                        size: 20,
                        color: selecionado == a && !t.highContrast
                            ? c.onAccent
                            : cores[n % 3],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        a.rotulo,
                        style: text.titleSmall?.copyWith(
                          color: selecionado == a && !t.highContrast
                              ? c.onAccent
                              : c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Resultado em linha, como a lista do Uber: ícone com a distância embaixo,
/// nome em destaque e detalhes, separados por linhas finas.
class _LinhaResultado extends StatelessWidget {
  const _LinhaResultado({
    required this.local,
    required this.ponto,
    required this.rota,
    required this.ultima,
    required this.hint,
    required this.onTap,
  });
  final Local local;
  final PontoReferencia ponto;
  final ResultadoRota rota;
  final bool ultima;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AcessaTheme.of(context);
    final c = t.colors;
    final text = Theme.of(context).textTheme;
    final r = rota;
    final distancia = switch (r) {
      Rota(etapas: final e) when e.isEmpty => 'Você já está aqui',
      Rota() => '${r.minutos} min a pé',
      SemRota(existeComEscada: true) => 'Só há caminho com escadas',
      SemRota() => 'Sem caminho cadastrado',
    };
    final metros = switch (r) {
      Rota(etapas: final e) when e.isEmpty => 'aqui',
      Rota() => '${r.distanciaM} m',
      SemRota() => '—',
    };
    final recursos = exibirRecursos(local.recursos);

    return Semantics(
      button: true,
      hint: hint,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: ultima
                  ? null
                  : Border(
                      bottom: BorderSide(color: c.border.withValues(alpha: .2)),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.highContrast ? c.surface : c.mapLine,
                          shape: BoxShape.circle,
                          border: t.highContrast
                              ? Border.all(color: c.ink, width: 2)
                              : null,
                        ),
                        child: Icon(
                          iconeDoLocal(local.icone),
                          size: 22,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metros,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AcessaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(local.nome, style: text.titleMedium),
                      Text(
                        '${exibir(ponto.piso)} · ${local.categoria}',
                        style: text.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
                      const SizedBox(height: 2),
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
