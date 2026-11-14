// Textos com partes variáveis: todos precisam de modelo de tradução.

import 'package:acessa_plus/app/i18n/i18n.dart';
import 'package:acessa_plus/features/welcome_preferences/preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const amostras = [
    'Balcão de Informações já é a última parada.',
    '3 min a pé',
    '2 paradas',
    'Mover Vitrine Moda para antes',
    'Mover Vitrine Moda para depois',
    'Parada 2',
    'Preferência: Atendimento presencial',
    'Procurando: Cadeira',
    'Procurar Porta',
    'Remover Vitrine Moda',
    'Remover a parada Vitrine Moda',
    'Resposta: Me siga',
    'Seguir para Praça de Alimentação',
    'Simular chegada: Praça de Alimentação',
    'Você chegou à parada 1',
    'cerca de 4 min a pé',
    '45 graus',
    'Vendo o Mezanino. Você está no Térreo.',
  ];

  for (final idioma in [AppLanguage.en, AppLanguage.es]) {
    test('modelos traduzem para ${idioma.name}', () {
      // Em espanhol, "parada" é igual ao português.
      const iguaisEmEs = {'2 paradas', 'Parada 2'};
      final faltando = [
        for (final s in amostras)
          if (traduzir(s, idioma) == s &&
              !(idioma == AppLanguage.es && iguaisEmEs.contains(s)))
            s,
      ];
      expect(faltando, isEmpty, reason: 'Sem tradução: $faltando');
    });
  }

  test('nomes próprios são preservados dentro do modelo', () {
    expect(
      traduzir('Seguir para Praça de Alimentação', AppLanguage.en),
      contains('Praça de Alimentação'),
    );
  });
}
