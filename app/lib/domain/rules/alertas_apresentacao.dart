import '../models/ocorrencia.dart';
import '../models/shopping.dart';
import 'ocorrencias.dart';

/// Textos e contas da interface do mapa colaborativo de alertas.
///
/// Funções puras, em português (a tela traduz com `tr`). Cada frase é um
/// texto inteiro para que a tradução por modelo funcione.

/// Limites da planta (unidades do cadastro, catalogo.json → "mapa").
const larguraPlanta = 400.0;
const alturaPlanta = 260.0;

/// Passo das setas que ajustam o pino no "Reportar problema".
const passoPino = 10.0;

/// "HH:MM" no horário do aparelho.
String horaMinuto(DateTime d) {
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}

/// "agora mesmo", "há 1 min", "há 12 min", "há 2 h".
String haQuanto(DateTime de, DateTime agora) {
  final min = agora.difference(de).inMinutes;
  if (min < 1) return 'agora mesmo';
  if (min < 60) return 'há $min min';
  return 'há ${min ~/ 60} h';
}

/// "1 confirmação" / "3 confirmações".
String textoConfirmacoes(int n) => n == 1 ? '1 confirmação' : '$n confirmações';

/// Situação do alerta em uma frase (o card de detalhes).
String textoSituacao(Ocorrencia o, DateTime agora) =>
    switch (situacao(o, agora)) {
      SituacaoOcorrencia.ativa =>
        'Ativo · ${textoConfirmacoes(o.confirmacoes)} · '
            'vale até ${horaMinuto(expiraEm(o))}',
      SituacaoOcorrencia.resolvida => 'Resolvido',
      SituacaoOcorrencia.expirada => 'Expirado',
    };

/// Horário do relato: "Criado às 10:05 · confirmado há 3 min".
String textoHorario(Ocorrencia o, DateTime agora) =>
    'Criado às ${horaMinuto(o.criadaEm)} · '
    'confirmado ${haQuanto(o.confirmadaEm, agora)}';

/// Nome do ponto de referência do alerta: o cadastrado ou o mais próximo.
String? nomeDoLocal(Ocorrencia o, Map<String, PontoReferencia> pontos) {
  final cadastrado = o.pontoId == null ? null : pontos[o.pontoId];
  if (cadastrado != null) return cadastrado.nome;
  return pontoMaisProximo(pontos.values, o.piso, o.x, o.y)?.nome;
}

/// Uma frase por alerta para o leitor de tela:
/// "Piso molhado ou escorregadio, perto de Praça de Eventos."
String fraseDoAlerta(Ocorrencia o, Map<String, PontoReferencia> pontos) {
  final local = nomeDoLocal(o, pontos);
  return local == null
      ? '${o.tipo.rotulo}.'
      : '${o.tipo.rotulo}, perto de $local.';
}

/// Resumo dos alertas de um piso para a descrição do mapa.
String resumoAlertasNoPiso(int n) => switch (n) {
  0 => 'Nenhum alerta da comunidade neste piso.',
  1 => '1 alerta da comunidade neste piso.',
  _ => '$n alertas da comunidade neste piso.',
};

/// Move o pino em ([dx], [dy]) passos, sem sair da planta.
({double x, double y}) moverPino(double x, double y, int dx, int dy) => (
  x: (x + dx * passoPino).clamp(0.0, larguraPlanta),
  y: (y + dy * passoPino).clamp(0.0, alturaPlanta),
);

/// Descrição curta digitada pelo visitante, já limpa e no limite.
/// `null` quando vazia.
String? descricaoLimpa(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  return t.length > NovaOcorrencia.maxDescricao
      ? t.substring(0, NovaOcorrencia.maxDescricao)
      : t;
}
