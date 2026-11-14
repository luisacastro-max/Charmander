# Arquitetura implementada

Base: `2a05442`, revisão em 14/11/2026. Complementa a proposta Word.

## Módulos

| Pasta em app/lib/ | Responsabilidade |
|---|---|
| app/ | MaterialApp, rotas, tema, tokens e movimento |
| core/widgets/ | Componentes reutilizáveis e semântica |
| domain/models/ | Pontos, locais, trechos e conteúdos de comunicação |
| domain/rules/ | Informação desconhecida, rotas e viagens |
| data/ | Carregamento e DadosScope |
| data/repositories/ | Interfaces e implementações JSON |
| features/welcome_preferences/ | Boas-vindas, preferências, controlador e armazenamento |
| features/destino/ | Busca e resumo/edição das paradas |
| features/navegacao/ | Etapas, bússola e mapa |

## Inicialização e estado

O main restaura preferências e carrega dados antes de abrir AcessaApp. Falha de leitura de preferências volta ao padrão. Falha inicial dos dados permite abrir o app sem dados pré-carregados.

Preferências usam ChangeNotifier, InheritedNotifier e shared_preferences. Dados são expostos por DadosScope. Busca, paradas e navegação mantêm estado nas telas. Ainda não existe coordenação central para retomada de percurso, conversa ou assistência.

EstadoNavegacao é imutável e substituído a cada chegada simulada. Percurso ativo não é persistido entre sessões.

## Rotas

O grafo usa pontos e trechos bidirecionais do JSON. Dijkstra encontra o menor custo:

- Sem escadas elimina trechos marcados com escada.
- Preferir elevador multiplica por seis o custo das trocas de piso por escada/escada rolante.
- Redução de estímulos multiplica por três o custo de trechos com movimento alto cadastrado.

As duas últimas opções são preferências de custo, não exclusões absolutas. A distância exibida soma metros, não custo ponderado. Tempo estimado: 50 metros/minuto, mínimo de um minuto.

A viagem calcula uma rota por parada na ordem definida pelo visitante. A interface limita a cinco paradas; não otimiza a ordem automaticamente. Uma perna incompatível é identificada sem remover restrições.

## Mapa e localização

Coordenadas são ilustrativas. A direção vem dos pontos do mapa, não do magnetômetro. O modo visual semelhante a GPS segue a etapa simulada, sem rastreamento físico. Chegadas são acionadas por botão; paradas intermediárias aguardam confirmação.

## Dados e integrações

JSON e fontes são assets locais. Apenas preferências e idioma persistem. Não há API própria, banco remoto, autenticação, serviço BLE operacional ou assistência real.

Interfaces de repositório permitem evolução para outras fontes; autenticação, sincronização, contratos e falhas remotas ainda precisarão ser implementados.

## Limitações identificadas

- Modelos de comunicação importam idioma da feature de preferências, criando dependência do domínio com a apresentação.
- Escritas de preferências não aguardam conclusão e ignoram falhas.
- O Future de dados fica em cache inclusive quando falha; nova chamada pode reutilizar o erro.
- Instrução de escada rolante usa “Suba” sem distinguir descida.

Consulte as [pendências](../backlog/pendencias.md). A documentação não corrige essas implementações.

