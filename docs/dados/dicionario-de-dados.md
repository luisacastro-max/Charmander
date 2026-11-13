# Dicionário de dados — Acessa+ (MVP)

Situação: **Etapa 2**. Todos os dados são **fictícios** e servem só para a demonstração.
Nenhum dado pessoal é coletado ou armazenado.

## Onde cada dado fica

| Dado | Arquivo / local | Duração |
|---|---|---|
| Pontos de referência e locais | `app/assets/data/catalogo.json` | Fixo, vem com o app |
| Trechos entre pontos | `app/assets/data/percursos.json` | Fixo, vem com o app |
| Cartões, mensagens rápidas, frases traduzidas, sugestões "Neste local" | `app/assets/data/comunicacao.json` | Fixo, vem com o app |
| Preferências e idioma | Armazenamento local do aparelho (`shared_preferences`; no navegador, `localStorage`) | Até o visitante apagar |
| Conversa, percurso ativo, solicitação | Memória da sessão (etapas futuras) | Até fechar o app |

## Regra de informação desconhecida (RNF08, RN06)

- Campo ausente ou vazio aparece como **"Não informado"** (`app/lib/domain/rules/informacao.dart`).
- Lista de recursos ausente ou vazia também aparece como "Não informado".
- Ausência de cadastro **nunca** é tratada como prova de que algo é ou não acessível.
- Exemplos no catálogo: o horário do banheiro e os recursos da escada não foram cadastrados.

## Ponto de referência (`pontos`)

Ponto do mapa associado a um beacon BLE **simulado** (RN09).

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | texto | sim | Código curto (ex.: `ELV`) |
| `nome` | texto | sim | Nome exibido |
| `piso` | texto | não | "Térreo" ou "Piso 1"; ausente = "Não informado" |
| `beacon` | texto | sim | Identificador do beacon simulado (ex.: `BLE-06`) |
| `x`, `y` | número | sim | Posição no mapa ilustrativo (300 × 200) |
| `tipo` | `entrada` · `servico` · `loja` · `alimentacao` · `escada` · `elevador` | sim | Tipo do ponto |
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
| `destino` | sim/não | não (padrão: sim) | Se pode ser destino de rota — a escada não pode |

## Trecho (`trechos`)

Ligação entre dois pontos, válida nos dois sentidos.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | texto | Código (T01…T11) |
| `de`, `para` | texto | Pontos ligados |
| `distanciaM` | inteiro | Distância estimada em metros |
| `escada` | sim/não | Tem degraus. **Rotas "sem escadas" nunca usam este trecho** (RN03) |
| `trocaPiso` | `elevador` · `rampa` · `escada` · vazio | Como muda de piso, quando muda |
| `movimento` | `normal` · `alto` | Movimento cadastrado; não é medição em tempo real (RN10) |

**Correção em relação ao protótipo HTML:** no protótipo só o trecho Balcão → Escada era marcado com degraus. Aqui o trecho Escada → Praça de Alimentação (a subida em si) também é marcado, e um teste garante que todo trecho que toca a escada tenha `escada = sim`.

## Comunicação

| Conjunto | Campos | Observação |
|---|---|---|
| `cartoes` | `id`, `icone`, `texto` | 8 cartões com símbolo + texto (RF27) |
| `mensagensRapidas` | `categoria`, `frases` | 6 categorias (RF27) |
| `frasesTraduzidas` | `id`, `pt`, `en`, `es` | 6 frases **traduzidas previamente**, não por tradução automática (RF28) |
| `sugestoesPorPonto` | `pontoId`, `titulo`, `acoes[]` | Cada ação tem `mensagem` **ou** `ativarPreferencia`; só executa por ação do visitante (RN14) |

## Preferências salvas no aparelho

Chaves com o prefixo `acessa.pref.`: `largeText`, `highContrast`, `audioGuidance`, `textCommunication`, `quickMessages`, `avoidStairs`, `preferElevators`, `simplified`, `calm` (sim/não) e `language` (`pt`, `en`, `es`).

- São **escolhas de recursos**, não informações sobre deficiência ou saúde (RN01).
- Valor ausente ou corrompido volta ao padrão (desativado / português).
- "Apagar minhas preferências" remove todas as chaves `acessa.pref.` deste aparelho, após confirmação (RNF13, CA14).

## Evolução prevista

As telas leem os dados por interfaces (`app/lib/data/repositories/repositorios.dart`). Numa versão integrada a um shopping, basta criar outra implementação (API Spring Boot + PostgreSQL) sem mudar as telas. Antes de qualquer armazenamento remoto, será preciso definir base legal e consentimento conforme a LGPD.
