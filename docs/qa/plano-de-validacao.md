# Plano de testes e validação

## Automação existente

Execute `flutter analyze` e `flutter test` em app/.

| Arquivo em app/test/ | Área |
|---|---|
| widget_test.dart | Boas-vindas, preferências, tema e semântica |
| destino_test.dart | Busca, filtro e origem simulada |
| navegacao_test.dart | Paradas, avanço, chegada e mapa |
| data/dados_test.dart | Integridade de catálogo e conteúdos |
| data/preferences_store_test.dart | Persistência e exclusão |
| data/rotas_test.dart | Restrições, elevador, custos e etapas |
| data/viagem_test.dart | Paradas, direção e estado de navegação |

Arquivos .feature nesta pasta descrevem cenários BDD. Não há runner Gherkin configurado; a automação correspondente está nos testes Dart citados nos cabeçalhos.

## Validação manual necessária

- Percorrer o fluxo com TalkBack e, quando disponível, VoiceOver.
- Conferir foco, ordem de leitura, rótulos, anúncios e teclado no navegador.
- Testar texto ampliado junto à escala do sistema em telas estreitas.
- Conferir alto contraste e redução de estímulos sem perda de conteúdo.
- Reabrir o app e confirmar restauração; apagar preferências e conferir nova abertura.
- Demonstrar rota sem escadas até a Praça de Alimentação e incompatibilidade do Mezanino.
- Adicionar, reordenar e remover paradas; conferir limite de cinco.
- Conferir chegada intermediária e final.
- Testar zoom, piso, rotação, visão da rota e recentralização.
- Testar recursos locais sem conexão após disponibilizar o app; não presumir instalação web offline.

## Evidências

Registrar commit, data, responsável, dispositivo/sistema, versões Flutter/Dart, comandos, resultados e evidências. Capturas antigas são histórico, não validação da versão atual.

A revisão documental não possui nova execução aprovada. Na análise anterior, o SDK bloqueou acesso a C:\flutter\bin\cache\lockfile. Resultados anteriores não devem ser tratados como aprovação desta revisão.

## Critério de entrega

Concluir análise estática, testes pertinentes e fluxo manual no aparelho da apresentação. Registrar falhas e limitações. Não declarar certificação ou acessibilidade integral apenas com testes de widgets.

