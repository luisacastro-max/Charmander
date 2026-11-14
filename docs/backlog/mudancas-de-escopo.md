# Mudanças de escopo aprovadas

Registro do PO. Cada mudança mantém os identificadores dos requisitos originais (Requisitos v0.4) e indica o que foi alterado.

## MUD-01 — Fluxo direto até a navegação (Etapa 3a, novembro de 2026)

**Pedido da equipe:** depois das preferências, levar o visitante direto a "Para onde você quer ir?" e, em seguida, a uma navegação com bússola e mapa interativo baseada na localização atual (beacons BLE simulados).

| Antes (documentos v0.4) | Depois |
|---|---|
| Boas-vindas → Preferências → Home → Explorar (T04) → Planejamento de rota (T05) → Navegação Viva (T06) | Boas-vindas → Preferências → **Para onde você quer ir?** (T04 + T05) → **Navegação com bússola e mapa** (T06, Etapa 3b) |
| Home como tela obrigatória após as preferências | Home continua no app, a um toque pela barra inferior (Etapa 4) |
| Shopping de 9 pontos em 2 pisos | Shopping fictício de 31 pontos em 3 níveis (Térreo, Mezanino, 2º piso) |

**Requisitos afetados (sem mudar os IDs):**

- RF07–RF11 (Explorar) e RF12–RF15 (Planejamento) passam a ser atendidos pela tela "Para onde você quer ir?" e pelo resumo da rota.
- RF51 (ponto atual simulado) passa para a tela "Para onde?" ("Você está aqui" + "Trocar").
- RF17–RF22 e RF48 (Navegação Viva) ganham bússola guiada pelo mapa e mapa interativo — Etapa 3b.
- RF05/RF06 (Home) continuam previstos, na Etapa 4.

**Decisões tomadas com a equipe:**

| Tema | Decisão |
|---|---|
| Planta enviada pela equipe | É um desenho técnico real de um shopping. Usada **só como inspiração** do formato geral (corredores, praça de eventos, praça de alimentação no 2º piso, escadas, banheiros, banheiro PNE, espaço família). **Nomes fictícios**, nenhuma área técnica ou de segurança e o PDF **fora do repositório público**. |
| Bússola | **Seta guiada pelo mapa** (aponta para o próximo ponto do percurso). Não usa o sensor magnético do celular. |
| Home | Continua acessível pela barra inferior. |
| Motor de rotas | Cálculo sobre pontos e trechos (opção B da arquitetura). |
| "Redução de estímulos" nas rotas | Também evita trechos cadastrados com muito movimento (RN10), quando existe alternativa. |

## MUD-02 — Rota com paradas (Etapa 3b, novembro de 2026)

**Pedido da equipe:** como nos apps de transporte, montar uma rota com mais de um ponto — por exemplo, "primeiro o elevador, depois a Praça de Alimentação".

| Tema | Decisão |
|---|---|
| Como adicionar | No resumo da rota, "Adicionar outra parada" abre a busca no modo "Qual a próxima parada?", com distâncias contadas a partir da parada anterior. |
| Ordem | Botões "Mover para antes/depois" e "Remover" (em vez de arrastar, para funcionar com leitor de tela e teclado). |
| Limite | 5 paradas, destino final incluído. |
| Sem caminho compatível | A parada que falhou é apontada; o app oferece removê-la e nunca desliga "Rotas sem escadas" por conta própria (RN04). |
| Na navegação | Ao chegar numa parada intermediária, a navegação espera o visitante tocar em "Seguir para …". |

**Requisitos afetados (sem mudar os IDs):** RF12–RF15 (planejamento) e RF17–RF22 (Navegação Viva) passam a aceitar várias paradas.

**Atualizações pendentes nos documentos Word** (para a equipe): Requisitos v0.4 (seções 7 e 8 — telas e fluxos), Proposta das 13 telas (seções 7 e 9) e Arquitetura (decisão do motor de rotas e do gerenciador de estado).

## Propostas aguardando aprovação

Itens abaixo **não estão aprovados**. Ficam aqui para a equipe decidir. MUD-03 está reservada para o atalho “Como você vai circular hoje?” (ver [pendências](pendencias.md)).

### MUD-04 (proposta) — Mapa colaborativo de alertas (novembro de 2026)

**Pedido da equipe:** inspirado nos alertas do Waze, permitir que visitantes relatem problemas de acessibilidade no shopping (piso molhado, elevador parado, passagem interditada etc.) e que esses relatos apareçam para outras pessoas e influenciem as rotas.

| Tema | Proposta |
|---|---|
| Natureza do dado | Relato da comunidade, anônimo e **não verificado**. Sempre identificado assim na tela. |
| Local | Ponto e andar confirmados pela pessoa numa mini-planta (posição indoor é imprecisa); lista “Perto de” para leitor de tela. |
| Efeito nas rotas | Bloqueio (interditada, elevador, rampa) retira o trecho; demais tipos encarecem o trecho e geram aviso. RN04 preservada: nunca sugerir escada a quem escolheu rotas sem escadas. |
| Ciclo de vida | Validade por tipo, renovada por “Ainda está aqui”; resolução por votos de sessões distintas; duplicados viram confirmação. |
| Compartilhamento | Servidor de demonstração (Node + arquivo JSON) na mesma rede; sem servidor, simulação local identificada. Não é produção. |
| Telas afetadas | Mapa da navegação (T06), resumo/cálculo de rota (T04 + T05) e novo formulário “Reportar problema”. |

**Requisitos afetados (sem mudar os IDs existentes):** RF12–RF15 e RF17–RF22 passam a considerar alertas ativos; RF48 (barreira e alternativa) ganha uma fonte de barreiras; RF36 (Ajuda+) é a saída quando não há caminho. Novos requisitos sugeridos: RF-A01 a RF-A08 e RN-A01 a RN-A07, descritos em [estado-atual.md](../requisitos/estado-atual.md), com numeração oficial a definir.

**Condições para aprovar como escopo de produção (não apenas demonstração):** decisão sobre moderação e abuso, autenticação, hospedagem do servidor, avaliação de Privacidade (LGPD) e Segurança da Informação, e validação com pessoas usuárias. Ver [pendências](pendencias.md).
