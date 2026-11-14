# Escopo e requisitos atuais

Revisão: 14/11/2026, base `2a05442`. IDs seguem requisitos Word v0.4. Fluxos atualizados por MUD-01 e MUD-02.

## Fluxo disponível

Boas-vindas → preferências → destino → resumo/edição das paradas → navegação simulada → chegada e novo destino.

Explorar e planejar foram aproximados no fluxo de destino. Home e barra inferior seguem planejadas. Navegação com paradas já existe nesta base.

## Rastreabilidade resumida

Avaliação por grupo; não representa cobertura integral de cada RF.

| Referência | Situação | Evidência / limite |
|---|---|---|
| RF01, RF03, RF04 | Parcial no conjunto | Boas-vindas e preferências; opções de áudio/comunicação ainda não entregam esses serviços |
| RF02 | Parcial | Idioma salvo; interface em português |
| RF44, RF47 | Implementado no fluxo de preferências | Salvar, restaurar e apagar sem login |
| RF05, RF06 | Planejado | Home e retomada ausentes |
| RF07–RF15 | Parcial no conjunto | Busca, filtros, origem, cálculo e paradas; Ajuda+ é provisório |
| RF16, RF17 | Implementado com simulação | Iniciar, avançar, progresso e chegada |
| RF18 | Parcial | Texto e mapa; áudio ausente no Flutter |
| RF19–RF22 | Parcial | Avanço e encerramento; pausa, ajuda e correção durante percurso precisam de evolução |
| RF23–RF35, RF46, RF49, RF62 | Planejado no Flutter | Dados de comunicação preparados; demonstrações no HTML |
| RF36–RF43 | Planejado no Flutter | Assistência e acompanhamento |
| RF45 | Pendente de validação/implementação completa | Revisão explícita de percurso ativo após mudança de mobilidade |
| RF48 | Planejado no Flutter | Barreira e escolha de rota alternativa |
| RF50 | Dados preparados | Card contextual pendente |
| RF51 | Parcial | Troca manual do ponto na escolha de destino |
| RF52–RF61 | Planejado no Flutter | Emergência e painel demonstrados no HTML |

## Regras preservadas

- Recursos individuais, sem diagnóstico obrigatório.
- Comunicação e mobilidade independentes.
- Sem escadas é restrição obrigatória e não é desativada em caso de incompatibilidade.
- Dado ausente é “Não informado”; não comprova acessibilidade.
- Movimento é cadastro, não medição de lotação ou ruído.
- Localização e distâncias são demonstrativas.

## Decisões e evolução

OCR permanece pendente. API Spring Boot, PostgreSQL, beacons físicos, Libras com atendimento humano e operação real são evoluções futuras. Não há promessa de tradução automática de Libras ou tradução livre de conversas.

Consulte o [plano de validação](../qa/plano-de-validacao.md). Presença no código não substitui validação com leitores de tela e aparelhos reais.

