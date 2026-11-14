// Textos e contas da interface do mapa colaborativo de alertas.

import 'package:acessa_plus/app/i18n/i18n.dart';
import 'package:acessa_plus/domain/models/ocorrencia.dart';
import 'package:acessa_plus/domain/models/shopping.dart';
import 'package:acessa_plus/domain/rules/alertas_apresentacao.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:flutter_test/flutter_test.dart';

final _agora = DateTime(2026, 11, 14, 10, 0);

Ocorrencia _alerta({
  TipoOcorrencia tipo = TipoOcorrencia.pisoMolhado,
  String? pontoId,
  int confirmacoes = 1,
  DateTime? resolvidaEm,
  DateTime? confirmadaEm,
}) => Ocorrencia(
  id: 'x',
  shoppingId: 'demo',
  tipo: tipo,
  piso: 'Térreo',
  x: 170,
  y: 158,
  pontoId: pontoId,
  criadaEm: DateTime(2026, 11, 14, 9, 5),
  confirmadaEm: confirmadaEm ?? DateTime(2026, 11, 14, 9, 48),
  confirmacoes: confirmacoes,
  resolvidaEm: resolvidaEm,
);

const _pev = PontoReferencia(
  id: 'PEV',
  nome: 'Praça de Eventos',
  piso: 'Térreo',
  beacon: 'BLE-08',
  x: 175,
  y: 160,
  tipo: TipoPonto.servico,
  saidaEmergencia: false,
);

void main() {
  test('horário e "há quanto tempo"', () {
    expect(horaMinuto(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(haQuanto(_agora, _agora), 'agora mesmo');
    expect(
      haQuanto(_agora.subtract(const Duration(minutes: 12)), _agora),
      'há 12 min',
    );
    expect(
      haQuanto(_agora.subtract(const Duration(minutes: 130)), _agora),
      'há 2 h',
    );
  });

  test('situação: ativo com confirmações e validade, resolvido, expirado', () {
    expect(
      textoSituacao(_alerta(confirmacoes: 3), _agora),
      'Ativo · 3 confirmações · vale até 11:48',
    );
    expect(textoSituacao(_alerta(), _agora), contains('1 confirmação'));
    expect(textoSituacao(_alerta(resolvidaEm: _agora), _agora), 'Resolvido');
    expect(
      textoSituacao(_alerta(), _agora.add(const Duration(hours: 3))),
      'Expirado',
    );
    expect(
      textoHorario(_alerta(), _agora),
      'Criado às 09:05 · confirmado há 12 min',
    );
  });

  test('local: ponto cadastrado ou o mais próximo; frase para leitor', () {
    expect(nomeDoLocal(_alerta(), {'PEV': _pev}), 'Praça de Eventos');
    expect(
      fraseDoAlerta(_alerta(), {'PEV': _pev}),
      'Piso molhado ou escorregadio, perto de Praça de Eventos.',
    );
    expect(resumoAlertasNoPiso(0), contains('Nenhum'));
    expect(resumoAlertasNoPiso(3), '3 alertas da comunidade neste piso.');
  });

  test('pino anda em passos e não sai da planta', () {
    expect(moverPino(100, 100, 1, 0), (x: 110.0, y: 100.0));
    expect(moverPino(0, 0, -1, -1), (x: 0.0, y: 0.0));
    expect(moverPino(400, 260, 1, 1), (x: 400.0, y: 260.0));
  });

  test('descrição: vazia vira null e respeita o limite', () {
    expect(descricaoLimpa('   '), isNull);
    expect(descricaoLimpa(' poça '), 'poça');
    expect(descricaoLimpa('a' * 200)!.length, NovaOcorrencia.maxDescricao);
  });

  test('tradução: tipos, situação e motivo com bloqueio por alerta', () {
    for (final t in TipoOcorrencia.values) {
      expect(traduzir(t.rotulo, AppLanguage.en), isNot(t.rotulo));
      expect(traduzir(t.rotulo, AppLanguage.es), isNotEmpty);
    }
    expect(
      traduzir('Ativo · 2 confirmações · vale até 11:48', AppLanguage.en),
      'Active · 2 confirmations · valid until 11:48',
    );
    expect(
      traduzir('Criado às 09:05 · confirmado há 12 min', AppLanguage.es),
      'Creada a las 09:05 · confirmada hace 12 min',
    );
    expect(
      traduzir(
        'Não há caminho sem escadas até Praça de Alimentação. '
        'Bloqueado por alerta da comunidade: Elevadores — Térreo.',
        AppLanguage.en,
      ),
      'There is no step-free path to Praça de Alimentação. '
      'Blocked by a community alert: Elevadores — Térreo.',
    );
    expect(
      traduzir(
        'Não encontramos caminho cadastrado até Praça de Alimentação. '
        'Em manutenção: Elevadores — Térreo. '
        'Bloqueado por alerta da comunidade: Rampa.',
        AppLanguage.es,
      ),
      'No encontramos camino registrado hasta Praça de Alimentação. '
      'En mantenimiento: Elevadores — Térreo. '
      'Bloqueado por una alerta de la comunidad: Rampa.',
    );
    expect(
      traduzir(
        'Alerta da comunidade no seu caminho: '
        'Piso molhado ou escorregadio, perto de Praça de Eventos.',
        AppLanguage.en,
      ),
      'Community alert on your way: Wet or slippery floor, near Praça de '
      'Eventos.',
    );
  });
}
