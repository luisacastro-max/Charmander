import '../../domain/models/ocorrencia.dart';

/// Alertas da comunidade (mapa colaborativo).
///
/// Diferente dos outros repositórios (JSON fixo), este é **compartilhado**:
/// o que uma pessoa registra aparece para as outras do mesmo shopping.
///
/// Implementações:
/// - `HttpOcorrenciasRepository` (`http_ocorrencias.dart`): fala com a API
///   de alertas. No MVP, a API é o servidor de demonstração
///   (`.claude/api-ocorrencias.js`); o contrato é o mesmo previsto para a
///   futura API Spring Boot (ver docs/arquitetura/arquitetura-atual.md).
/// - `SimuladoOcorrenciasRepository` (`simulado_ocorrencias.dart`):
///   **simulação** em memória, sem compartilhamento entre aparelhos. A tela
///   avisa quando este modo está em uso. Também é usado nos testes, com
///   duas sessões sobre o mesmo servidor simulado.
abstract interface class OcorrenciasRepository {
  /// `true` quando os alertas vão para um servidor compartilhado.
  /// `false` = simulação só neste aparelho (a tela mostra o aviso).
  bool get compartilhado;

  /// Alertas do shopping, atualizados sem recarregar a tela. Emite a lista
  /// inteira a cada mudança (inclui resolvidos e expirados recentes; a
  /// situação é calculada no app com `domain/rules/ocorrencias.dart`).
  /// Erros de conexão chegam como [FalhaOcorrencias] no fluxo, que continua
  /// tentando.
  Stream<List<Ocorrencia>> observar(String shoppingId);

  /// Registra um relato. Se já houver alerta ativo igual por perto
  /// (duplicado), o servidor confirma o existente em vez de criar outro.
  Future<ResultadoRegistro> registrar(NovaOcorrencia nova);

  /// "Ainda está aqui".
  Future<Ocorrencia> confirmar(String id);

  /// "Já foi resolvido".
  Future<Ocorrencia> marcarResolvida(String id);

  /// Libera conexões e temporizadores.
  void fechar();
}

class ResultadoRegistro {
  const ResultadoRegistro(this.ocorrencia, {this.duplicada = false});
  final Ocorrencia ocorrencia;

  /// O relato foi somado a um alerta que já existia.
  final bool duplicada;
}

/// Falha ao falar com o serviço de alertas (sem conexão, servidor fora,
/// resposta inválida). [mensagem] é curta, em português, para a tela.
class FalhaOcorrencias implements Exception {
  const FalhaOcorrencias(this.mensagem);
  final String mensagem;

  @override
  String toString() => 'FalhaOcorrencias: $mensagem';
}
