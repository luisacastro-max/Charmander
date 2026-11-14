/// RNF08 / RN06 — informação desconhecida.
///
/// Dado ausente aparece como "Não informado" e nunca é interpretado como
/// comprovação (ou negação) de acessibilidade.
const naoInformado = 'Não informado';

/// Texto pronto para exibir: o próprio valor ou "Não informado".
String exibir(String? valor) =>
    (valor == null || valor.trim().isEmpty) ? naoInformado : valor.trim();

/// Lista de recursos para exibir. Lista vazia ou ausente vira
/// ["Não informado"] — ausência de cadastro não significa ausência de recurso.
List<String> exibirRecursos(List<String>? recursos) =>
    (recursos == null || recursos.isEmpty) ? const [naoInformado] : recursos;
