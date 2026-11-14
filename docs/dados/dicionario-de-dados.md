# Dicionário de dados — Acessa+ (MVP)

Situação: **Etapa 3a** (shopping fictício v2, ver MUD-01 em `docs/backlog/mudancas-de-escopo.md`). Todos os dados são **fictícios** e servem só para a demonstração.
Nenhum dado pessoal é coletado ou armazenado. Os alertas da comunidade guardam só o problema relatado e um identificador anônimo e aleatório da sessão (resumido em hash no servidor), sem nome, contato ou localização da pessoa.

## Onde cada dado fica

| Dado | Arquivo / local | Duração |
|---|---|---|
| Pontos de referência e locais | `app/assets/data/catalogo.json` | Fixo, vem com o app |
| Trechos entre pontos | `app/assets/data/percursos.json` | Fixo, vem com o app |
| Cartões, mensagens rápidas, frases traduzidas, sugestões "Neste local" | `app/assets/data/comunicacao.json` | Fixo, vem com o app |
| Preferências e idioma | Armazenamento local do aparelho (`shared_preferences`; no navegador, `localStorage`) | Até o visitante apagar |
| Conversa, percurso ativo, solicitação | Memória da sessão (etapas futuras) | Até fechar o app |
| Alertas da comunidade (`Ocorrencia`) | Modo compartilhado: servidor de demonstração, `.claude/dados/ocorrencias.json` (fora do git). Modo simulado: memória do aparelho | Compartilhado: até 24 h depois de resolvido ou expirado. Simulado: até fechar o app |
| Identificador anônimo da sessão | Memória do app; no servidor, só um resumo (hash SHA-256 truncado) junto ao alerta | Até fechar o app; no servidor, enquanto o alerta existir |

## Regra de informação desconhecida (RNF08, RN06)

- Campo ausente ou vazio aparece como **"Não informado"** (`app/lib/domain/rules/informacao.dart`).
- Lista de recursos ausente ou vazia também aparece como "Não informado".
- Ausência de cadastro **nunca** é tratada como prova de que algo é ou não acessível.
- Exemplos no catálogo: o horário e os recursos dos Banheiros do Térreo e o horário da Livraria Página não foram cadastrados.

## O shopping fictício (v2)

- **31 pontos** em 3 níveis: Térreo, Mezanino e 2º piso. Inclui corredores (só para cálculo de rota, não aparecem como destino).
- **22 locais**: lojas, alimentação, serviços, banheiros (2 acessíveis), saídas e circulação.
- **37 trechos** (`percursos.json` versão 3), com elevador, escada rolante e escadas.
- **Desvio pela acessibilidade**: a escada rolante desembarca na Praça de Alimentação (trecho `T37`) e os elevadores ficam mais afastados. Da Entrada Principal até a Praça, a rota mais usada sobe pela escada rolante (148 m); sem escadas, a rota dá a volta pelo elevador (182 m, +34 m).
- **Galeria do Mezanino**: acesso **somente por escada** — usada para demonstrar RN04 (rota incompatível).
- Formato geral inspirado numa planta de 2 pisos enviada pela equipe. **Nomes, lojas e medidas são inventados; nenhuma área técnica ou de segurança foi incluída**, e um teste automático confere isso.

## Ponto de referência (`pontos`)

Ponto do mapa associado a um beacon BLE **simulado** (RN09).

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | texto | sim | Código curto (ex.: `ELV`) |
| `nome` | texto | sim | Nome exibido |
| `piso` | texto | não | "Térreo" ou "Piso 1"; ausente = "Não informado" |
| `beacon` | texto | sim | Identificador do beacon simulado (ex.: `BLE-06`) |
| `x`, `y` | número | sim | Posição no mapa ilustrativo (300 × 200) |
| `tipo` | `entrada` · `servico` · `loja` · `alimentacao` · `escada` · `elevador` · `corredor` | sim | Tipo do ponto |
| `saidaEmergencia` | sim/não | não | Se é saída usada na emergência simulada (RF53) |

## Local (`locais`)

Estabelecimento ou serviço consultado em Explorar (RF07–RF10).

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | texto | sim | Código do local |
| `pontoId` | texto | sim | Ponto de referência onde fica |
| `nome` | texto | sim | Nome exibido |
| `categoria` | texto | sim | Lojas, Alimentação, Serviços ou Circulação |
| `icone` | texto | sim | Chave do ícone usado pela interface |
| `descricao` | texto | não | Descrição curta |
| `recursos` | lista de textos | não | Recursos de acessibilidade cadastrados |
| `horario` | texto | não | Horário de funcionamento |
| `destino` | sim/não | não (padrão: sim) | Se pode ser destino de rota |
| `acessivel` | sim/não | não | Marcado como acessível no cadastro (ex.: banheiro PNE) |
| `palavrasChave` | lista de textos | não | Termos extras da busca (ex.: "wc", "fraldário"); a busca ignora acentos |

## Trecho (`trechos`)

Ligação entre dois pontos, válida nos dois sentidos.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | texto | Código (T01…T37) |
| `de`, `para` | texto | Pontos ligados |
| `distanciaM` | inteiro | Distância estimada em metros |
| `escada` | sim/não | Tem degraus. **Rotas "sem escadas" nunca usam este trecho** (RN03) |
| `trocaPiso` | `elevador` · `rampa` · `escada` · `escadaRolante` · vazio | Como muda de piso, quando muda |
| `movimento` | `normal` · `alto` | Movimento cadastrado; não é medição em tempo real (RN10) |

**Regra conservadora:** todo trecho que chega a uma escada ou escada rolante é marcado com `escada = sim` (inclusive a aproximação), para que rotas "sem escadas" nem cheguem perto delas. Um teste automático garante isso.

**Motor de rotas** (`app/lib/domain/rules/rotas.dart`): calcula o caminho de menor custo. "Sem escadas" remove trechos com escada; "Preferência por elevadores" encarece trocas de piso por escada; "Redução de estímulos" encarece trechos com muito movimento. Sem rota compatível, informa e oferece alternativas, sem remover restrições (RN04).

**Trechos indisponíveis (simulação):** `CriteriosRota.indisponiveis` recebe ids de trechos fora de uso (ex.: `T23`, elevador em manutenção). Nenhuma rota usa esses trechos; se por causa deles não houver rota, `SemRota.bloqueios` lista os trechos e o motivo termina com "Em manutenção: …". A informação é só da demonstração: não vem de sistema real nem é gravada (não é dado pessoal). `Rota.trechosDeElevador` / `Viagem.trechosDeElevador` dizem quais elevadores a rota usa.

**Rota adaptada** (`app/lib/domain/rules/rota_adaptada.dart`): `compararRota` / `compararViagem` calculam a rota mais usada (sem preferências pessoais, mesmos trechos indisponíveis) e a rota adaptada às preferências, e devolvem se mudou, escadas/escadas rolantes evitadas, elevadores/rampas usados no lugar e metros/minutos a mais.

## Comunicação

| Conjunto | Campos | Observação |
|---|---|---|
| `cartoes` | `id`, `icone`, `texto` | 8 cartões com símbolo + texto (RF27) |
| `mensagensRapidas` | `categoria`, `frases` | 6 categorias (RF27) |
| `frasesTraduzidas` | `id`, `pt`, `en`, `es` | 6 frases **traduzidas previamente**, não por tradução automática (RF28) |
| `cartoesAjuda` | `id`, `icone`, `pt`, `en`, `es` | Frases do **cartão de ajuda** para mostrar a outra pessoa. `{destino}` é trocado pelo nome do destino da rota. Traduções **a revisar por pessoa fluente** antes de uso real |
| `respostasRapidas` | `id`, `pt`, `en`, `es` | Respostas que a outra pessoa toca no cartão (Sim, Não, Me siga...) |
| `sugestoesPorPonto` | `pontoId`, `titulo`, `acoes[]` | Cada ação tem `mensagem` **ou** `ativarPreferencia`; só executa por ação do visitante (RN14) |

## Alerta da comunidade (`Ocorrencia`)

Relato de um visitante sobre um problema num ponto/andar do shopping (mapa colaborativo). É **relato da comunidade**, não verificação oficial nem garantia de segurança. Modelo: `app/lib/domain/models/ocorrencia.dart`; regras: `app/lib/domain/rules/ocorrencias.dart` (repetidas no servidor `.claude/api-ocorrencias.js`; mudou uma, mude a outra).

### Novo relato (`NovaOcorrencia`, corpo do `POST /api/ocorrencias`)

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `shoppingId` | texto | sim | 1 a 40 caracteres `[A-Za-z0-9_-]`. No MVP, sempre `demo` |
| `tipo` | texto | sim | Um dos tipos da tabela abaixo |
| `piso` | texto | sim | Nome do piso (ex.: `Térreo`), até 40 caracteres |
| `x`, `y` | número | sim | Posição na planta, nas mesmas unidades de `pontos[].x/y` |
| `pontoId` | texto | não | Ponto de referência mais próximo, para descrever o local em texto |
| `descricao` | texto | não | Até 140 caracteres (sem espaços nas pontas). **Não deve conter dado pessoal**; a tela avisa |

### Alerta registrado (`Ocorrencia`, devolvido pela API)

| Campo | Tipo | Regra |
|---|---|---|
| `id` | texto | Gerado pelo servidor (UUID no servidor de demonstração; `sim-N` no modo simulado) |
| `shoppingId`, `tipo`, `piso`, `x`, `y`, `pontoId`, `descricao` | — | Como no relato |
| `criadaEm` | data/hora ISO 8601 (UTC) | Quando foi relatado |
| `confirmadaEm` | data/hora ISO 8601 (UTC) | Último "Ainda está aqui" (ou a criação). O prazo conta daqui |
| `confirmacoes` | inteiro ≥ 1 | Sessões diferentes que relataram ou confirmaram |
| `resolucoes` | inteiro ≥ 0 | Sessões diferentes que disseram "Já foi resolvido" desde a última confirmação |
| `resolvidaEm` | data/hora ISO 8601 (UTC), opcional | Quando foi dado como resolvido |

O app **nunca** recebe quem confirmou ou resolveu, só as contagens. O servidor guarda, por alerta, os resumos (hash) das sessões que confirmaram e votaram, apenas para não contar duas vezes a mesma sessão.

### Tipos, validade e efeito na rota

| `tipo` | Rótulo | Validade sem confirmação | Efeito |
|---|---|---|---|
| `pisoMolhado` | Piso molhado ou escorregadio | 2 h | Aviso (custo ×4) |
| `passagemInterditada` | Passagem interditada | 8 h | Bloqueia o trecho |
| `obstaculo` | Obstáculo no caminho | 2 h | Aviso (custo ×4) |
| `elevadorParado` | Elevador fora de serviço | 12 h | Bloqueia o elevador |
| `escadaRolanteParada` | Escada rolante parada | 12 h | Aviso (custo ×3) |
| `rampaBloqueada` | Rampa bloqueada | 6 h | Bloqueia a rampa (ou o corredor mais próximo, se não houver rampa perto) |
| `localCheio` | Local muito cheio | 1 h | Aviso (custo ×2,5) |
| `outro` | Outro problema | 3 h | Aviso (custo ×2) |

### Situação e regras

- **Ativa** enquanto `agora < confirmadaEm + validade` e sem `resolvidaEm`. Só alertas ativos afetam rotas.
- **Expirada** a partir de `confirmadaEm + validade`. **Resolvida** quando `resolvidaEm` existe.
- **Duplicado:** relato com mesmo shopping, tipo e piso a até 30 unidades de um alerta ativo vira confirmação do existente (o mais próximo); a API responde `duplicada: true`.
- **"Ainda está aqui":** renova `confirmadaEm`, soma 1 em `confirmacoes` (só se a sessão ainda não tinha confirmado), zera `resolucoes` e reabre se estava resolvido.
- **"Já foi resolvido":** 1 voto por sessão; resolve com `min(2, confirmacoes)` votos.
- **Trechos afetados:** elevador, escada rolante e rampa afetam trechos de troca de piso desse tipo cujo ponto fica a até 40 unidades; os demais afetam corredores do mesmo piso a até 22 unidades (ou o mais próximo, a até 44).
- **Retenção:** no servidor de demonstração, resolvidos e expirados há mais de 24 h saem da lista e do arquivo.

## Preferências salvas no aparelho

Chaves com o prefixo `acessa.pref.`: `largeText`, `highContrast`, `audioGuidance`, `textCommunication`, `quickMessages`, `avoidStairs`, `preferElevators`, `simplified`, `calm` (sim/não) e `language` (`pt`, `en`, `es`).

- São **escolhas de recursos**, não informações sobre deficiência ou saúde (RN01).
- Valor ausente ou corrompido volta ao padrão (desativado / português).
- "Apagar minhas preferências" remove todas as chaves `acessa.pref.` deste aparelho, após confirmação (RNF13, CA14).

## Evolução prevista

As telas leem os dados por interfaces (`app/lib/data/repositories/repositorios.dart`). Numa versão integrada a um shopping, basta criar outra implementação (API Spring Boot + PostgreSQL) sem mudar as telas. Os alertas da comunidade já usam a interface `OcorrenciasRepository`, com implementação HTTP e simulada; o contrato da API está em `docs/arquitetura/arquitetura-atual.md`. Antes de armazenamento remoto em produção, será preciso definir base legal, retenção, moderação e passar por avaliação de Segurança da Informação e Privacidade (LGPD).
