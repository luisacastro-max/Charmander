import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../data/repositories/ocorrencias_repositorio.dart';
import '../../data/repositories/simulado_ocorrencias.dart';
import '../../data/shopping_data.dart';
import '../../domain/models/ocorrencia.dart';
import '../../domain/rules/ocorrencias.dart' as regras;
import '../../domain/rules/rotas.dart';

/// Shopping demonstrativo (único no MVP). Alertas são separados por
/// shopping; o piso fica em cada alerta.
const shoppingDemo = 'demo';

/// Situação de um relato enviado por esta sessão.
enum EstadoEnvio { enviando, falhou }

/// Relato que esta sessão está enviando (ou que falhou). Aparece no mapa
/// como "Enviando…" ou "Não enviado" até o servidor confirmar.
class EnvioPendente {
  EnvioPendente(this.nova, this.chave);
  final NovaOcorrencia nova;
  final int chave;
  EstadoEnvio estado = EstadoEnvio.enviando;
  String? erro;
}

/// O que esta sessão já fez com um alerta (para não votar duas vezes).
enum AcaoLocal { confirmou, resolveu }

/// Estado dos alertas da comunidade para as telas.
///
/// Assina o repositório (compartilhado ou simulado), guarda envios
/// pendentes com "Tentar de novo" e calcula o impacto nas rotas.
class AlertasController extends ChangeNotifier {
  AlertasController(
    this.repositorio, {
    this.shoppingId = shoppingDemo,
    DateTime Function()? relogio,
  }) : relogio = relogio ?? DateTime.now;

  /// Simulação local: não compartilha entre aparelhos (aviso na tela).
  factory AlertasController.simulado({DateTime Function()? relogio}) =>
      AlertasController(
        SimuladoOcorrenciasRepository(
          ServidorSimulado(relogio: relogio),
          sessao: sessaoAnonima(),
        ),
        relogio: relogio,
      );

  final OcorrenciasRepository repositorio;
  final String shoppingId;
  final DateTime Function() relogio;

  StreamSubscription<List<Ocorrencia>>? _sub;
  Timer? _relogioTimer;

  List<Ocorrencia> _todas = const [];
  bool _carregando = true;
  String? _erroConexao;
  final List<EnvioPendente> _pendentes = [];
  final Map<String, AcaoLocal> _acoes = {};
  Set<TipoOcorrencia> _tiposVisiveis = TipoOcorrencia.values.toSet();
  var _chave = 0;

  /// Relatos de todos (inclui resolvidos/expirados recentes).
  List<Ocorrencia> get todas => _todas;

  /// Primeira carga ainda não chegou.
  bool get carregando => _carregando;

  /// Última falha de conexão (null quando está tudo bem).
  String? get erroConexao => _erroConexao;

  bool get compartilhado => repositorio.compartilhado;

  List<EnvioPendente> get pendentes => List.unmodifiable(_pendentes);

  Set<TipoOcorrencia> get tiposVisiveis => _tiposVisiveis;

  bool get filtrando => _tiposVisiveis.length != TipoOcorrencia.values.length;

  AcaoLocal? acaoLocal(String id) => _acoes[id];

  /// Alertas ativos agora (os únicos que afetam rotas).
  List<Ocorrencia> get ativas => regras.ativas(_todas, relogio());

  /// Ativos visíveis no mapa, respeitando o filtro de categoria e,
  /// se dado, o piso.
  List<Ocorrencia> visiveis({String? piso}) => [
    for (final o in ativas)
      if (_tiposVisiveis.contains(o.tipo) && (piso == null || o.piso == piso))
        o,
  ];

  Ocorrencia? porId(String id) {
    for (final o in _todas) {
      if (o.id == id) return o;
    }
    return null;
  }

  SituacaoOcorrencia situacao(Ocorrencia o) => regras.situacao(o, relogio());

  /// Começa a ouvir o servidor. Pode ser chamado de novo para reconectar.
  void iniciar() {
    _sub?.cancel();
    _sub = repositorio
        .observar(shoppingId)
        .listen(
          (l) {
            _todas = l;
            _carregando = false;
            _erroConexao = null;
            notifyListeners();
          },
          onError: (Object e) {
            _carregando = false;
            _erroConexao = e is FalhaOcorrencias
                ? e.mensagem
                : 'Não foi possível carregar os alertas.';
            notifyListeners();
          },
        );
    // Reavalia expirações de minuto em minuto, mesmo sem novidades.
    _relogioTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => notifyListeners(),
    );
  }

  /// "Tentar de novo" depois de falha de conexão.
  void reconectar() {
    _erroConexao = null;
    _carregando = true;
    notifyListeners();
    iniciar();
  }

  void alternarTipo(TipoOcorrencia t) {
    final s = {..._tiposVisiveis};
    if (!s.remove(t)) s.add(t);
    _tiposVisiveis = s;
    notifyListeners();
  }

  void mostrarTodosOsTipos() {
    _tiposVisiveis = TipoOcorrencia.values.toSet();
    notifyListeners();
  }

  /// Registra um relato. Devolve o resultado, ou `null` se falhou (o envio
  /// fica em [pendentes] com estado [EstadoEnvio.falhou]).
  Future<ResultadoRegistro?> reportar(NovaOcorrencia nova) {
    final p = EnvioPendente(nova, ++_chave);
    _pendentes.add(p);
    notifyListeners();
    return _enviar(p);
  }

  Future<ResultadoRegistro?> tentarDeNovo(EnvioPendente p) {
    p
      ..estado = EstadoEnvio.enviando
      ..erro = null;
    notifyListeners();
    return _enviar(p);
  }

  void descartar(EnvioPendente p) {
    _pendentes.remove(p);
    notifyListeners();
  }

  Future<ResultadoRegistro?> _enviar(EnvioPendente p) async {
    try {
      final r = await repositorio.registrar(p.nova);
      _pendentes.remove(p);
      _acoes[r.ocorrencia.id] = AcaoLocal.confirmou;
      _mesclar(r.ocorrencia);
      notifyListeners();
      return r;
    } catch (e) {
      p
        ..estado = EstadoEnvio.falhou
        ..erro = e is FalhaOcorrencias
            ? e.mensagem
            : 'Não foi possível enviar o alerta.';
      notifyListeners();
      return null;
    }
  }

  /// "Ainda está aqui". Lança [FalhaOcorrencias] em caso de erro (a tela
  /// mostra e oferece tentar de novo).
  Future<void> confirmar(String id) async {
    final o = await repositorio.confirmar(id);
    _acoes[id] = AcaoLocal.confirmou;
    _mesclar(o);
    notifyListeners();
  }

  /// "Já foi resolvido". Lança [FalhaOcorrencias] em caso de erro.
  Future<void> marcarResolvida(String id) async {
    final o = await repositorio.marcarResolvida(id);
    _acoes[id] = AcaoLocal.resolveu;
    _mesclar(o);
    notifyListeners();
  }

  void _mesclar(Ocorrencia o) {
    _todas = [
      for (final x in _todas)
        if (x.id != o.id) x,
      o,
    ];
  }

  /// Impacto dos alertas ativos nas rotas (bloqueios e avisos).
  regras.ImpactoAlertas impacto(ShoppingData dados) =>
      regras.impactoNasRotas(_todas, dados.motor, dados.pontos, relogio());

  /// Critérios [c] com os alertas ativos aplicados.
  CriteriosRota aplicar(CriteriosRota c, ShoppingData dados) =>
      impacto(dados).aplicar(c);

  @override
  void dispose() {
    _sub?.cancel();
    _relogioTimer?.cancel();
    repositorio.fechar();
    super.dispose();
  }
}

/// Identificador anônimo e aleatório desta sessão. Serve só para o
/// servidor não contar duas vezes a mesma confirmação; não identifica a
/// pessoa e não é salvo.
String sessaoAnonima() {
  final r = math.Random.secure();
  return List.generate(
    16,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Disponibiliza o [AlertasController] para a árvore de widgets.
class AlertasScope extends InheritedNotifier<AlertasController> {
  const AlertasScope({
    super.key,
    required AlertasController controller,
    required super.child,
  }) : super(notifier: controller);

  static AlertasController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlertasScope>()?.notifier;

  static AlertasController of(BuildContext context) => maybeOf(context)!;
}
