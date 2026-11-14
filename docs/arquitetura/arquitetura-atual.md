# Arquitetura implementada

Revisão de 14/11/2026 sobre edbc8e9, integrado à main por 4cb0ea1. [Documento consolidado](../documentacao-tecnica.md).

## Estrutura e responsabilidades

| Local em app/lib/ | Responsabilidade |
|---|---|
| app/ | Aplicação, rotas, tema, tokens e movimento |
| core/widgets/ | Componentes e semântica compartilhados |
| domain/models/ | Pontos, locais, trechos e conteúdos de comunicação |
| domain/rules/ | Rotas, viagens, comparação rota mais usada x rota adaptada (`rota_adaptada.dart`), procura e assistência |
| data/repositories/ | Contratos e implementações JSON |
| data/shopping_data.dart | Carga e DadosScope |
| features/welcome_preferences/ | Boas-vindas, ajustes e armazenamento |
| features/destino/ | Pesquisa, origem e paradas |
| features/navegacao/ | Progresso e mapa |
| features/comunicacao/ | Cartão de frases e respostas |
| features/ajuda/ | Pedido, revisão e acompanhamento |
| features/ultimo_metro/ | Procura em cena fictícia |

## Inicialização e estado

main restaura preferências, carrega dados e escolhe o serviço de alertas (compartilhado ou simulado). AcessaApp aplica o tema e os escopos. Preferências usam ChangeNotifier, InheritedNotifier e shared_preferences. DadosScope expõe o shopping. Estado local de widgets coordena busca, paradas, cartão e pedido; não há Provider, Riverpod ou Bloc.

EstadoNavegacao representa progresso imutável. PedidoAjuda contém categoria, local, preferência e estados demonstrativos. Voltar de ajuda ao percurso preserva a tela na pilha; fechar o app não restaura viagem ou pedido.

## Regras

Dijkstra calcula menor custo no grafo bidirecional. Sem escadas remove trechos; preferência por elevador multiplica por seis o custo de escada/escada rolante entre pisos; caminho tranquilo multiplica por três trechos de movimento alto. Metros exibidos são a distância física cadastrada, não o custo.

Viagens calculam uma perna por parada na ordem escolhida. O limite da interface é cinco. Não há otimização automática da ordem.

A direção usa coordenadas do desenho, não sensores físicos. Último metro calcula objetos visíveis em cena fixa; não usa câmera.

## Fontes de dados e extensão

JSON empacotado e interfaces CatalogoRepository, PercursoRepository e ComunicacaoRepository. Os alertas da comunidade são a exceção: usam OcorrenciasRepository, compartilhado por HTTP ou simulado (seção abaixo). Substituir fontes por API no futuro também exigirá contratos, falhas, sincronização e autenticação, quando aplicáveis.

## Alertas da comunidade (mapa colaborativo)

Visitantes relatam problemas (piso molhado, passagem interditada, elevador fora de serviço etc.) num ponto/andar; o alerta aparece para os outros usuários do mesmo shopping sem recarregar a tela e influencia o cálculo de rotas. São **relatos da comunidade**, não verificação oficial.

| Peça | Local |
|---|---|
| Modelo (`TipoOcorrencia`, `NovaOcorrencia`, `Ocorrencia`) | `app/lib/domain/models/ocorrencia.dart` |
| Regras puras (duplicado, validade, confirmar, resolver, trechos afetados, impacto nas rotas) | `app/lib/domain/rules/ocorrencias.dart` |
| Rotas com alertas (`CriteriosRota.bloqueadosPorAlerta`, `penalidades`; `SemRota.bloqueiosPorAlerta`) | `app/lib/domain/rules/rotas.dart` |
| Contrato | `OcorrenciasRepository` em `app/lib/data/repositories/ocorrencias_repositorio.dart` |
| Cliente HTTP (compartilhado) | `app/lib/data/repositories/http_ocorrencias.dart` |
| Simulação em memória | `app/lib/data/repositories/simulado_ocorrencias.dart` |
| Estado para as telas | `AlertasController` / `AlertasScope` em `app/lib/features/alertas/alertas_controller.dart` |
| Servidor de demonstração | `.claude/api-ocorrencias.js`, montado em `.claude/serve-web.js` |

### Modos: compartilhado x simulado

`main.dart` escolhe o repositório na inicialização (em paralelo com preferências e dados):

1. Endereço: `--dart-define=OCORRENCIAS_API=<url>` se definido; senão, na web, a mesma origem (`/api/ocorrencias`). Fora da web, sem endereço, não há API.
2. Testa `GET <base>/saude` com tempo máximo de 2 s e só aceita `{"ok": true}` (um servidor que devolve `index.html` para tudo não conta).
3. Respondeu: `HttpOcorrenciasRepository` (**compartilhado**, `compartilhado == true`). Não respondeu: `AlertasController.simulado()` (**simulação** só neste aparelho, `compartilhado == false`; a tela mostra o aviso).

No modo compartilhado, "sem recarregar" é feito por *polling* a cada 3 s: o cliente só emite quando a lista muda, transforma falha/tempo esgotado (8 s) em `FalhaOcorrencias` no fluxo e continua tentando; o temporizador para quando a tela deixa de ouvir. Depois de registrar, confirmar ou resolver, o cliente consulta na hora.

### Contrato da API

Prefixo `/api/ocorrencias`. JSON em UTF-8. Toda chamada `POST` leva `X-Sessao: <id anônimo>` (8 a 64 caracteres `[A-Za-z0-9_-]`, aleatório por abertura do app; serve só para não contar duas vezes o voto da mesma sessão). Campos em `docs/dados/dicionario-de-dados.md`.

| Método e caminho | Corpo | Sucesso | Observação |
|---|---|---|---|
| `GET /saude` | — | `200 {"ok": true}` | Usado na escolha do modo |
| `GET ?shopping=ID` | — | `200 {"ocorrencias": [Ocorrencia], "agora": ISO}` | Inclui resolvidos/expirados recentes; a situação é calculada no app |
| `POST /` | `NovaOcorrencia` | `201 {"ocorrencia", "duplicada": false}` ou `200 {"ocorrencia", "duplicada": true}` | Duplicado vira confirmação do alerta existente |
| `POST /{id}/confirmar` | — | `200 {"ocorrencia"}` | "Ainda está aqui" |
| `POST /{id}/resolver` | — | `200 {"ocorrencia"}` | "Já foi resolvido"; voto repetido não conta |

Erros: `{"erro": "mensagem curta em português"}`.

| Código | Quando |
|---|---|
| 400 | Campo obrigatório ausente ou inválido, descrição acima de 140 caracteres, JSON inválido, sessão ausente, `shopping` ausente |
| 404 | Alerta inexistente (ou removido após 24 h) / caminho desconhecido |
| 405 | Método não suportado |
| 413 | Corpo acima de 4 KB |
| 415 | Corpo que não é `application/json` |
| 429 | Mais de 5 relatos por sessão (ou 20 por endereço) por minuto |
| 500 | Erro interno |

No app, qualquer falha vira `FalhaOcorrencias` com mensagem curta; a tela mostra o erro e oferece tentar de novo. Relatos que falharam ficam pendentes no `AlertasController`.

### Servidor de demonstração: limites

`node .claude/serve-web.js 8097` serve o build web (`app/build/web`) e a API na mesma origem (configs `acessa-web-build` e `acessa-web-celular` de `.claude/launch.json`). Para `flutter run` na 8093, use `--dart-define=OCORRENCIAS_API=http://localhost:8097/api/ocorrencias` (CORS liberado só para `localhost`, `127.0.0.1` e `[::1]`). Teste de fumaça: `node .claude/api-ocorrencias.test.js`.

- **Não é produção.** Sem autenticação, sem moderação de conteúdo, sem HTTPS próprio, um processo só.
- Persistência num arquivo JSON (`.claude/dados/ocorrencias.json`, fora do git), com escrita atômica (arquivo temporário + renomear). Sobrevive a reinícios; não escala para vários processos.
- Limite simples de relatos por minuto, em memória (zera ao reiniciar). Qualquer pessoa na mesma rede pode criar sessões novas.
- Guarda só resumos (hash) dos ids de sessão; não registra em log o conteúdo dos pedidos nem endereços.
- As regras repetem as do Dart; mudanças precisam ser feitas nos dois lugares (testes: `app/test/data/ocorrencias_regras_test.dart` e o teste de fumaça).

Não existe compartilhamento de alertas em produção: o modo compartilhado só existe enquanto o servidor de demonstração estiver rodando.

### Plano de migração para Spring Boot

1. **API REST com o mesmo contrato** (Spring Boot + PostgreSQL): tabela `ocorrencia` (campos do dicionário) e tabelas `ocorrencia_confirmacao` / `ocorrencia_resolucao` com chave única (`ocorrencia_id`, `sessao_hash`) para garantir um voto por sessão no banco. Regras de duplicado/validade/resolução num serviço de domínio, com testes portados dos casos do Dart e do teste de fumaça. Remoção após 24 h por tarefa agendada.
2. **Tempo real com SSE** (`GET /api/ocorrencias/stream?shopping=ID`, `text/event-stream`, evento com a lista ou a alteração); WebSocket só se surgir necessidade de canal bidirecional. No app, `HttpOcorrenciasRepository.observar` passa a usar o stream e mantém o *polling* como alternativa quando o SSE cair. Nenhuma tela muda: elas dependem de `OcorrenciasRepository` via `AlertasController`.
3. **Antes de abrir ao público:** autenticação do app (token de dispositivo ou do shopping), limite de taxa no gateway, moderação (filtro da descrição, denúncia, remoção pelo shopping), HTTPS, retenção e base legal definidas, e avaliação de Segurança da Informação e Privacidade. Integração com sistemas reais do shopping (manutenção de elevadores, por exemplo) só com decisão registrada.
4. **Desligar o servidor de demonstração** depois que a API real passar no mesmo conjunto de testes de contrato.

## Limitações

Modelos de comunicação dependem do enum de idioma da feature de preferências. Escritas de preferências não aguardam conclusão e ignoram falhas. Cache de carga pode conservar Future com erro. Escada rolante usa “Suba” sem distinguir descida. Consulte [pendências](../backlog/pendencias.md).

Voz e internacionalização ampliada estavam em alterações locais, fora da base publicada desta revisão.