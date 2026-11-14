# Arquitetura implementada

Revisão de 14/11/2026 sobre edbc8e9, integrado à main por 4cb0ea1. [Documento consolidado](../documentacao-tecnica.md).

## Estrutura e responsabilidades

| Local em app/lib/ | Responsabilidade |
|---|---|
| app/ | Aplicação, rotas, tema, tokens e movimento |
| core/widgets/ | Componentes e semântica compartilhados |
| domain/models/ | Pontos, locais, trechos e conteúdos de comunicação |
| domain/rules/ | Rotas, viagens, procura e assistência |
| data/repositories/ | Contratos e implementações JSON |
| data/shopping_data.dart | Carga e DadosScope |
| features/welcome_preferences/ | Boas-vindas, ajustes e armazenamento |
| features/destino/ | Pesquisa, origem e paradas |
| features/navegacao/ | Progresso e mapa |
| features/comunicacao/ | Cartão de frases e respostas |
| features/ajuda/ | Pedido, revisão e acompanhamento |
| features/ultimo_metro/ | Procura em cena fictícia |

## Inicialização e estado

main restaura preferências e carrega dados. AcessaApp aplica o tema e os escopos. Preferências usam ChangeNotifier, InheritedNotifier e shared_preferences. DadosScope expõe o shopping. Estado local de widgets coordena busca, paradas, cartão e pedido; não há Provider, Riverpod ou Bloc.

EstadoNavegacao representa progresso imutável. PedidoAjuda contém categoria, local, preferência e estados demonstrativos. Voltar de ajuda ao percurso preserva a tela na pilha; fechar o app não restaura viagem ou pedido.

## Regras

Dijkstra calcula menor custo no grafo bidirecional. Sem escadas remove trechos; preferência por elevador multiplica por seis o custo de escada/escada rolante entre pisos; caminho tranquilo multiplica por três trechos de movimento alto. Metros exibidos são a distância física cadastrada, não o custo.

Viagens calculam uma perna por parada na ordem escolhida. O limite da interface é cinco. Não há otimização automática da ordem.

A direção usa coordenadas do desenho, não sensores físicos. Último metro calcula objetos visíveis em cena fixa; não usa câmera.

## Fontes de dados e extensão

JSON empacotado e interfaces CatalogoRepository, PercursoRepository e ComunicacaoRepository. Substituir fontes por API no futuro também exigirá contratos, falhas, sincronização e autenticação, quando aplicáveis.

## Limitações

Modelos de comunicação dependem do enum de idioma da feature de preferências. Escritas de preferências não aguardam conclusão e ignoram falhas. Cache de carga pode conservar Future com erro. Escada rolante usa “Suba” sem distinguir descida. Consulte [pendências](../backlog/pendencias.md).

Voz e internacionalização ampliada estavam em alterações locais, fora da base publicada desta revisão.
