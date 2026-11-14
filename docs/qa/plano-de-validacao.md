# Plano de testes e validação

Base publicada: edbc8e9, integrada à main por 4cb0ea1. Revisão documental: 14/11/2026.

## Automação

Executar em app/: `flutter analyze` e `flutter test`. Para cobertura opcional: `flutter test --coverage`.

| Arquivo em app/test/ | Área |
|---|---|
| widget_test.dart | Boas-vindas, preferências, tema e semântica |
| destino_test.dart | Busca, filtro e origem |
| navegacao_test.dart | Paradas, avanço e mapa |
| cartao_ajuda_test.dart | Frases traduzidas, respostas e frente a frente |
| ajuda_test.dart | Pedido, revisão, estados e retorno ao percurso |
| encontrar_test.dart | Cena fictícia, gestos e sinais |
| data/dados_test.dart | Integridade dos JSON |
| data/preferences_store_test.dart | Persistência e exclusão |
| data/rotas_test.dart | Restrições e cálculo |
| data/viagem_test.dart | Paradas e estado de navegação |

Os arquivos .feature são especificações BDD. Não há runner Gherkin configurado; testes Dart fazem a automação relacionada.

## Validação manual

- Usar TalkBack e, quando houver dispositivo, VoiceOver.
- Conferir foco, ordem, rótulos, anúncios e teclado no navegador.
- Testar fonte ampliada com escala do sistema em telas estreitas.
- Conferir alto contraste e movimento reduzido.
- Salvar, reabrir e apagar preferências.
- Calcular rota sem escadas e demonstrar incompatibilidade do Mezanino.
- Adicionar, reordenar e remover paradas; confirmar limite de cinco.
- Avançar por pontos, conferir pisos, zoom e recentralização.
- Selecionar frases, idioma do leitor, respostas e frente a frente.
- Revisar local e pedido, avançar estados, cancelar e retomar percurso.
- Testar último metro com cena e direção simuladas, sem pressupor câmera real.
- Conferir recursos locais sem conexão depois de disponibilizar o app, sem presumir instalação web offline.

## Evidências e resultado desta revisão

Registrar data, commit, responsável, dispositivo, sistema, versões Flutter/Dart, comandos e resultados. Capturas históricas não comprovam o build atual. Cobertura de linhas não equivale a requisitos integralmente atendidos.

Esta revisão validou documentação e links, sem nova execução aprovada do Flutter. Na análise anterior, houve bloqueio do lockfile do SDK. Testes de voz e i18n encontrados localmente não integram a base publicada documentada.

Antes da apresentação, executar o fluxo no aparelho escolhido e registrar falhas. Não declarar certificação ou acessibilidade integral apenas com testes de widgets.
