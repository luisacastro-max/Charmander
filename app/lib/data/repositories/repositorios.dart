import '../../domain/models/comunicacao.dart';
import '../../domain/models/shopping.dart';

/// Interfaces dos repositórios.
///
/// No MVP as implementações leem JSON local (`json_repositorios.dart`).
/// Numa versão futura (API Spring Boot), basta criar outra implementação
/// destas interfaces — as telas não mudam.

abstract interface class CatalogoRepository {
  Future<List<PontoReferencia>> pontos();
  Future<List<Local>> locais();
}

abstract interface class PercursoRepository {
  Future<List<Trecho>> trechos();
}

abstract interface class ComunicacaoRepository {
  Future<List<CartaoComunicacao>> cartoes();
  Future<List<CategoriaMensagens>> mensagensRapidas();
  Future<List<FraseTraduzida>> frasesTraduzidas();
  Future<List<SugestoesDoPonto>> sugestoesPorPonto();
}
