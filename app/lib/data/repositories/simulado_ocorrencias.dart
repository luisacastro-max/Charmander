import 'dart:async';

import '../../domain/models/ocorrencia.dart';
import '../../domain/rules/ocorrencias.dart' as regras;
import 'ocorrencias_repositorio.dart';

/// **Simulação** do servidor de alertas, em memória.
///
/// Não compartilha nada entre aparelhos: serve para a demonstração sem
/// servidor e para os testes. Várias sessões (repositórios) sobre o mesmo
/// [ServidorSimulado] se enxergam, como usuários diferentes num servidor
/// real — é assim que os testes validam o compartilhamento.
class ServidorSimulado {
  ServidorSimulado({DateTime Function()? relogio})
    : relogio = relogio ?? DateTime.now;

  final DateTime Function() relogio;
  final _ocorrencias = <String, Ocorrencia>{};
  final _confirmadoPor = <String, Set<String>>{};
  final _resolvidoPor = <String, Set<String>>{};
  final _mudou = StreamController<void>.broadcast(sync: true);
  var _seq = 0;

  /// Próximas N operações falham (para testar erro e "Tentar de novo").
  int falharProximas = 0;

  /// Atraso artificial de cada operação (estado "Enviando…").
  Duration atraso = Duration.zero;

  List<Ocorrencia> lista(String shoppingId) => [
    for (final o in _ocorrencias.values)
      if (o.shoppingId == shoppingId) o,
  ];

  Future<void> _operacao() async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    if (falharProximas > 0) {
      falharProximas--;
      throw const FalhaOcorrencias(
        'Não foi possível falar com o serviço de alertas.',
      );
    }
  }

  void _salvar(Ocorrencia o) {
    _ocorrencias[o.id] = o;
    _mudou.add(null);
  }

  Ocorrencia _buscar(String id) =>
      _ocorrencias[id] ??
      (throw const FalhaOcorrencias('Este alerta não existe mais.'));

  Future<ResultadoRegistro> registrar(NovaOcorrencia n, String sessao) async {
    await _operacao();
    final agora = relogio();
    final dup = regras.duplicadaDe(_ocorrencias.values, n, agora);
    if (dup != null) {
      return ResultadoRegistro(_confirmar(dup, sessao, agora), duplicada: true);
    }
    final o = Ocorrencia(
      id: 'sim-${++_seq}',
      shoppingId: n.shoppingId,
      tipo: n.tipo,
      piso: n.piso,
      x: n.x,
      y: n.y,
      pontoId: n.pontoId,
      descricao: n.descricao?.trim().isEmpty ?? true
          ? null
          : n.descricao!.trim(),
      criadaEm: agora,
      confirmadaEm: agora,
    );
    _confirmadoPor[o.id] = {sessao};
    _resolvidoPor[o.id] = {};
    _salvar(o);
    return ResultadoRegistro(o);
  }

  Ocorrencia _confirmar(Ocorrencia o, String sessao, DateTime agora) {
    final por = _confirmadoPor[o.id] ??= {};
    // A mesma sessão confirmando de novo só renova o prazo.
    final nova = por.add(sessao)
        ? regras.confirmar(o, agora)
        : o.copyWith(confirmadaEm: agora, resolucoes: 0, limparResolvida: true);
    _resolvidoPor[o.id] = {};
    _salvar(nova);
    return nova;
  }

  Future<Ocorrencia> confirmar(String id, String sessao) async {
    await _operacao();
    return _confirmar(_buscar(id), sessao, relogio());
  }

  Future<Ocorrencia> marcarResolvida(String id, String sessao) async {
    await _operacao();
    final o = _buscar(id);
    final por = _resolvidoPor[id] ??= {};
    if (!por.add(sessao)) return o; // voto repetido não conta
    final nova = regras.votarResolvida(o, relogio());
    _salvar(nova);
    return nova;
  }

  /// Todos os alertas de um shopping (para assinantes).
  ///
  /// Feito com [StreamController] (e não `async*` + `await for`): assim o
  /// cancelamento do assinante termina na hora e solta a inscrição em
  /// [_mudou]; com o gerador, `cancel()` não completava.
  Stream<List<Ocorrencia>> observar(String shoppingId) {
    StreamSubscription<void>? mudancas;
    late final StreamController<List<Ocorrencia>> saida;
    saida = StreamController<List<Ocorrencia>>(
      onListen: () {
        saida.add(lista(shoppingId));
        mudancas = _mudou.stream.listen((_) => saida.add(lista(shoppingId)));
      },
      onCancel: () => mudancas?.cancel(),
    );
    return saida.stream;
  }
}

/// Uma "sessão" (aparelho) usando o [ServidorSimulado].
class SimuladoOcorrenciasRepository implements OcorrenciasRepository {
  SimuladoOcorrenciasRepository(this.servidor, {required this.sessao});

  final ServidorSimulado servidor;

  /// Identificador anônimo e aleatório da sessão (não é dado pessoal).
  final String sessao;

  @override
  bool get compartilhado => false;

  @override
  Stream<List<Ocorrencia>> observar(String shoppingId) =>
      servidor.observar(shoppingId);

  @override
  Future<ResultadoRegistro> registrar(NovaOcorrencia nova) =>
      servidor.registrar(nova, sessao);

  @override
  Future<Ocorrencia> confirmar(String id) => servidor.confirmar(id, sessao);

  @override
  Future<Ocorrencia> marcarResolvida(String id) =>
      servidor.marcarResolvida(id, sessao);

  @override
  void fechar() {}
}
