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

**Atualizações pendentes nos documentos Word** (para a equipe): Requisitos v0.4 (seções 7 e 8 — telas e fluxos), Proposta das 13 telas (seções 7 e 9) e Arquitetura (decisão do motor de rotas e do gerenciador de estado).
