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

## PROPOSTA — Mapa colaborativo de alertas (novo escopo, em desenvolvimento)

Situação: proposta de novo escopo, ainda não aprovada nem incorporada ao Word v0.4. A numeração abaixo é **sugestão** (prefixo “A” de alertas) para não colidir com IDs oficiais; ao aprovar, a equipe atribui números definitivos no Word (sugestão: continuar após o último RF/RN existente). Mudança registrada como [MUD-04 (proposta)](../backlog/mudancas-de-escopo.md). Cenários: [alertas-comunidade.feature](../qa/alertas-comunidade.feature).

Inspiração: alertas do Waze, adaptados à acessibilidade no shopping. Relaciona-se a RF12–RF15, RF17–RF22, RF36 (Ajuda+), RF45, RF48, RN01, RN02, RN04 e RNF13.

| ID proposto | Requisito proposto |
|---|---|
| RF-A01 | Botão “Reportar problema” no mapa e durante a rota, com 8 tipos: piso molhado ou escorregadio; passagem interditada; obstáculo no caminho; elevador fora de serviço; escada rolante parada; rampa bloqueada; local muito cheio; outro problema. Descrição opcional de até 140 caracteres. |
| RF-A02 | Confirmar ponto e andar numa mini-planta com ajuste manual; alternativa por lista “Perto de” para leitor de tela. |
| RF-A03 | Marcador aparece para as demais sessões do mesmo shopping e andar sem recarregar (atualização a cada ~3 s). |
| RF-A04 | Card do marcador com tipo, descrição, local, andar, horário e situação; ações “Ainda está aqui” e “Já foi resolvido”; identificado como relato da comunidade, não verificado. |
| RF-A05 | Alertas ativos influenciam o cálculo de rota: bloqueio retira o trecho; aviso encarece o trecho e gera aviso. Sem alternativa acessível, explicar e oferecer “Pedir ajuda”. |
| RF-A06 | Durante a navegação, alerta novo no caminho restante gera aviso e oferta de recálculo. |
| RF-A07 | Filtro por categoria e andar; agrupamento de marcadores próximos; forma do marcador diferencia bloqueio de aviso (não só cor). |
| RF-A08 | Compartilhamento por servidor de demonstração; sem servidor, simulação local identificada na tela. |
| RN-A01 | Passagem interditada, elevador fora de serviço e rampa bloqueada **bloqueiam** o trecho; os demais tipos **encarecem** o trecho. Nunca sugerir escada a quem escolheu rotas sem escadas (reforça RN04). |
| RN-A02 | Validade por tipo, renovada a cada “Ainda está aqui”: piso molhado 2 h; interditada 8 h; obstáculo 2 h; elevador 12 h; escada rolante 12 h; rampa 6 h; local cheio 1 h; outro 3 h. Expirado deixa de afetar. |
| RN-A03 | Resolvido com min(2, nº de confirmações) votos “Já foi resolvido” de sessões distintas; “Ainda está aqui” zera os votos. Resolvido deixa de afetar. |
| RN-A04 | Mesmo tipo e andar a até 30 unidades da planta de um alerta ativo vira confirmação do existente. |
| RN-A05 | Sessão = identificador anônimo aleatório, não salvo, usado só para não contar voto duas vezes. |
| RN-A06 | Nenhum dado pessoal é pedido; a descrição traz aviso para não incluir dados pessoais. |
| RN-A07 | Tudo que for simulação local (sem servidor) aparece identificado; o servidor de demonstração não é produção (sem autenticação e sem moderação). |

Limites conhecidos: posição indoor é imprecisa (por isso o ajuste manual); relatos não são verificados por funcionários; não há integração com status oficial de equipamentos do shopping; o servidor de demonstração (Node + arquivo JSON) não roda na publicação estática da Vercel. Pendências em [pendencias.md](../backlog/pendencias.md).

## Regras e limites

Preferências não exigem diagnóstico; mobilidade e comunicação são independentes. Rota incompatível não remove restrições. Dado desconhecido aparece como “Não informado”. BLE, cenas e assistência são simulados e não acionam serviços reais.

Traduções ampliadas da interface, mensagens rápidas adicionais e flutter_tts estavam em desenvolvimento local. Não são automaticamente parte do código público documentado.

Consulte [documentação técnica](../documentacao-tecnica.md) e [plano de validação](../qa/plano-de-validacao.md). Testes precisam de evidência de execução; presença no código não equivale a homologação.