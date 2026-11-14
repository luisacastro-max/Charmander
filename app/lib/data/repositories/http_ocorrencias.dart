import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/ocorrencia.dart';
import 'ocorrencias_repositorio.dart';

/// Alertas da comunidade numa API HTTP **compartilhada** entre sessões.
///
/// No MVP a API é o servidor de demonstração (`.claude/api-ocorrencias.js`,
/// sem autenticação nem moderação; não é produção). O contrato é o descrito
/// em docs/arquitetura/arquitetura-atual.md e vale também para a futura API
/// Spring Boot:
///
/// - `GET  {base}?shopping=ID` → `{"ocorrencias": [Ocorrencia...]}`
/// - `POST {base}` (NovaOcorrencia) → `{"ocorrencia": ..., "duplicada": bool}`
/// - `POST {base}/{id}/confirmar` → `{"ocorrencia": ...}`
/// - `POST {base}/{id}/resolver` → `{"ocorrencia": ...}`
/// - `GET  {base}/saude` → `{"ok": true}`
///
/// Toda chamada leva o cabeçalho `X-Sessao` com o identificador anônimo da
/// sessão (só para o servidor não contar duas vezes o mesmo voto).
///
/// "Sem recarregar a tela" é feito por *polling* a cada [intervalo]; a
/// migração prevista troca por SSE/WebSocket sem mudar a interface.
class HttpOcorrenciasRepository implements OcorrenciasRepository {
  HttpOcorrenciasRepository(
    Uri base, {
    required this.sessao,
    http.Client? client,
    this.intervalo = const Duration(seconds: 3),
    this.timeout = const Duration(seconds: 8),
  }) : base = _semBarraFinal(base),
       _client = client ?? http.Client(),
       _clienteProprio = client == null;

  /// Endereço da coleção de alertas (ex.: `https://host/api/ocorrencias`).
  final Uri base;

  /// Identificador anônimo e aleatório da sessão (não é dado pessoal).
  final String sessao;

  /// Intervalo entre consultas de [observar].
  final Duration intervalo;

  /// Tempo máximo de cada requisição.
  final Duration timeout;

  final http.Client _client;
  final bool _clienteProprio;
  final Set<_Consulta> _consultas = {};

  @override
  bool get compartilhado => true;

  /// A API responde em `{base}/saude` dentro de [timeout]? Usado na
  /// inicialização para decidir entre o modo compartilhado e o simulado.
  static Future<bool> disponivel(
    Uri base, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final c = client ?? http.Client();
    try {
      final r = await c
          .get(_caminho(_semBarraFinal(base), ['saude']))
          .timeout(timeout);
      if (r.statusCode != 200) return false;
      final j = jsonDecode(r.body);
      return j is Map && j['ok'] == true;
    } catch (_) {
      return false;
    } finally {
      if (client == null) c.close();
    }
  }

  static Uri _semBarraFinal(Uri u) => u.replace(
    pathSegments: [
      for (final s in u.pathSegments)
        if (s.isNotEmpty) s,
    ],
  );

  static Uri _caminho(Uri base, List<String> extra) =>
      base.replace(pathSegments: [...base.pathSegments, ...extra]);

  Map<String, String> get _cabecalhos => {
    'Accept': 'application/json',
    'X-Sessao': sessao,
  };

  @override
  Stream<List<Ocorrencia>> observar(String shoppingId) {
    late final _Consulta consulta;
    final controller = StreamController<List<Ocorrencia>>(
      onListen: () {
        _consultas.add(consulta);
        consulta.iniciar();
      },
      onCancel: () {
        _consultas.remove(consulta);
        consulta.parar();
      },
    );
    consulta = _Consulta(this, shoppingId, controller);
    return controller.stream;
  }

  Future<List<Ocorrencia>> _listar(String shoppingId) async {
    final j = await _enviar(
      () => _client.get(
        base.replace(queryParameters: {'shopping': shoppingId}),
        headers: _cabecalhos,
      ),
    );
    final lista = j is Map ? j['ocorrencias'] : j;
    if (lista is! List) throw const FalhaOcorrencias(_msgResposta);
    try {
      return [
        for (final o in lista) Ocorrencia.fromJson(o as Map<String, dynamic>),
      ];
    } catch (_) {
      throw const FalhaOcorrencias(_msgResposta);
    }
  }

  @override
  Future<ResultadoRegistro> registrar(NovaOcorrencia nova) async {
    final j = await _enviar(
      () => _client.post(
        base,
        headers: {..._cabecalhos, 'Content-Type': 'application/json'},
        body: jsonEncode(nova.toJson()),
      ),
    );
    final r = ResultadoRegistro(
      _ocorrenciaDe(j),
      duplicada: j is Map && j['duplicada'] == true,
    );
    _atualizarAgora();
    return r;
  }

  @override
  Future<Ocorrencia> confirmar(String id) => _acao(id, 'confirmar');

  @override
  Future<Ocorrencia> marcarResolvida(String id) => _acao(id, 'resolver');

  Future<Ocorrencia> _acao(String id, String acao) async {
    final j = await _enviar(
      () => _client.post(_caminho(base, [id, acao]), headers: _cabecalhos),
    );
    final o = _ocorrenciaDe(j);
    _atualizarAgora();
    return o;
  }

  Ocorrencia _ocorrenciaDe(Object? j) {
    try {
      final o = j is Map && j['ocorrencia'] is Map ? j['ocorrencia'] : j;
      return Ocorrencia.fromJson(o as Map<String, dynamic>);
    } catch (_) {
      throw const FalhaOcorrencias(_msgResposta);
    }
  }

  /// Depois de uma ação, as outras telas desta sessão não esperam o
  /// próximo ciclo para ver o resultado.
  void _atualizarAgora() {
    for (final c in [..._consultas]) {
      c.agora();
    }
  }

  /// Faz a requisição e devolve o JSON; qualquer falha vira
  /// [FalhaOcorrencias] com mensagem curta.
  Future<Object?> _enviar(Future<http.Response> Function() req) async {
    final http.Response r;
    try {
      r = await req().timeout(timeout);
    } on TimeoutException {
      throw const FalhaOcorrencias(
        'O serviço de alertas não respondeu. Verifique a conexão.',
      );
    } catch (_) {
      throw const FalhaOcorrencias('Sem conexão com o serviço de alertas.');
    }
    Object? j;
    try {
      j = r.body.isEmpty ? null : jsonDecode(r.body);
    } on FormatException {
      j = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (j == null) throw const FalhaOcorrencias(_msgResposta);
      return j;
    }
    throw FalhaOcorrencias(_mensagemDeErro(r.statusCode, j));
  }

  static String _mensagemDeErro(int status, Object? j) {
    // Mensagens do servidor de demonstração já são curtas e em português.
    final doServidor = j is Map ? j['erro'] : null;
    if (status < 500 &&
        doServidor is String &&
        doServidor.isNotEmpty &&
        doServidor.length <= 120) {
      return doServidor;
    }
    return switch (status) {
      400 || 413 || 415 => 'O alerta não pôde ser aceito. Confira os dados.',
      404 => 'Este alerta não existe mais.',
      429 => 'Muitos relatos em pouco tempo. Aguarde um minuto.',
      _ when status >= 500 =>
        'O serviço de alertas está com problema. Tente de novo.',
      _ => 'Não foi possível falar com o serviço de alertas.',
    };
  }

  static const _msgResposta = 'Resposta inválida do serviço de alertas.';

  @override
  void fechar() {
    for (final c in [..._consultas]) {
      c.parar();
    }
    _consultas.clear();
    if (_clienteProprio) _client.close();
  }
}

/// Polling de um shopping para um assinante. Emite só quando a lista muda
/// (ou na primeira resposta depois de uma falha, para a tela sair do erro).
class _Consulta {
  _Consulta(this.repo, this.shoppingId, this.saida);

  final HttpOcorrenciasRepository repo;
  final String shoppingId;
  final StreamController<List<Ocorrencia>> saida;

  Timer? _timer;
  bool _ativa = false;
  bool _buscando = false;
  bool _repetir = false;
  String? _ultima;

  void iniciar() {
    _ativa = true;
    _buscar();
  }

  void parar() {
    _ativa = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Consulta já (sem esperar o intervalo).
  void agora() {
    if (!_ativa) return;
    if (_buscando) {
      _repetir = true;
      return;
    }
    _timer?.cancel();
    _buscar();
  }

  Future<void> _buscar() async {
    _buscando = true;
    try {
      final lista = await repo._listar(shoppingId);
      if (!_ativa) return;
      final assinatura = jsonEncode([for (final o in lista) o.toJson()]);
      if (assinatura != _ultima) {
        _ultima = assinatura;
        saida.add(lista);
      }
    } catch (e) {
      if (!_ativa) return;
      _ultima = null; // ao voltar, emite de novo mesmo sem mudança
      saida.addError(
        e is FalhaOcorrencias
            ? e
            : const FalhaOcorrencias('Não foi possível carregar os alertas.'),
      );
    } finally {
      _buscando = false;
    }
    if (!_ativa) return;
    if (_repetir) {
      _repetir = false;
      _buscar();
    } else {
      _timer = Timer(repo.intervalo, _buscar);
    }
  }
}
