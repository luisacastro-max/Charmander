# Escopo e requisitos atuais

Revisão: 14/11/2026. Base publicada: edbc8e9, integrada à main por 4cb0ea1. IDs seguem requisitos Word v0.4; alterações de fluxo: MUD-01 e MUD-02.

## Jornada

Boas-vindas → preferências → destino → paradas → navegação simulada → chegada. Cartão de comunicação e Ajuda+ também têm entrada nas boas-vindas e na navegação. Ao chegar, há demonstração de procura de objetos.

## Rastreabilidade resumida

Avaliação por grupo, sem declarar cumprimento integral de cada requisito.

| Referências | Situação na base publicada |
|---|---|
| RF01, RF03, RF04 | Boas-vindas e preferências; recursos de áudio ainda incompletos |
| RF02 | Idioma salvo e frases do cartão em pt/en/es; interface predominantemente em português |
| RF44, RF47 | Preferências locais e uso sem cadastro |
| RF05, RF06 | Atalhos iniciais existentes; Home completa e retomada após reabrir pendentes |
| RF07–RF15 | Busca, origem, filtros, cálculo e até cinco paradas; conferir cada critério na avaliação |
| RF16, RF17 | Início, avanço, progresso e chegada simulados |
| RF18 | Texto e mapa; síntese de voz em trabalho local, fora desta base |
| RF19–RF22 | Avanço, encerramento e ajuda contextual; demais controles requerem validação/evolução |
| RF23–RF35, RF46, RF49, RF62 | Atendimento parcial por cartão e respostas; chat livre, voz para texto e Libras não entregues |
| RF36–RF43 | Pedido, revisão e acompanhamento demonstrativos; validar critérios com os testes e fluxo |
| RF45 | Revisão explícita de percurso ativo ainda precisa de validação/implementação completa |
| RF48 | Barreira e alternativa no Flutter pendentes |
| RF50 | Sugestões cadastradas; card contextual pendente |
| RF51 | Ponto atual simulado e troca na escolha de destino |
| RF52–RF61 | Emergência e painel como referência HTML, não implementados no Flutter |

“Último metro” amplia a demonstração com cena fictícia. Não implementa OCR ou visão computacional real.

## Regras e limites

Preferências não exigem diagnóstico; mobilidade e comunicação são independentes. Rota incompatível não remove restrições. Dado desconhecido aparece como “Não informado”. BLE, cenas e assistência são simulados e não acionam serviços reais.

Traduções ampliadas da interface, mensagens rápidas adicionais e flutter_tts estavam em desenvolvimento local. Não são automaticamente parte do código público documentado.

Consulte [documentação técnica](../documentacao-tecnica.md) e [plano de validação](../qa/plano-de-validacao.md). Testes precisam de evidência de execução; presença no código não equivale a homologação.
