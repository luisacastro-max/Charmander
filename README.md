# Acessa+ — Acessibilidade que conecta pessoas

Projeto da equipe **Charmander** para o hackathon 2026.

O Acessa+ propõe reduzir barreiras de comunicação, orientação e mobilidade em shopping centers, reunindo três pilares: **Comunicação Universal**, **Navegação Viva** e **Ajuda+**.

## Protótipo interativo

O [protótipo HTML](prototipo/index.html) apresenta as telas e os fluxos da proposta. Para experimentar, baixe o arquivo e abra-o em um navegador. O GitHub exibe o código do HTML ao abrir esse link.

**Como acessar:** abra o link do protótipo acima, clique em **Download raw file** (ícone de download) e abra o arquivo `index.html` no Chrome, Edge ou outro navegador. Não é necessário instalar o aplicativo ou configurar o GitHub Pages.

### Roteiro de demonstração

1. Na tela de boas-vindas, selecione **Começar**.
2. Ajuste as preferências e selecione **Continuar para o início**.
3. Explore os atalhos de comunicação, navegação, estabelecimentos e assistência.
4. Use os controles de simulação para testar pontos de referência e evolução dos atendimentos.

O HTML é um protótipo de interface. A proposta para o aplicativo mobile é Flutter e Dart; este repositório ainda não contém a implementação Flutter.

## Documentação da entrega

| Entrega | Arquivo | Situação |
|---|---|---|
| Documentação de requisitos | [Requisitos v0.4](docs/requisitos/requisitos-v0.4.docx) | Documento preliminar |
| Arquitetura proposta | [Proposta de arquitetura](docs/arquitetura/proposta-de-arquitetura.docx) | Proposta com decisões pendentes |
| Linguagem e justificativa técnica | [Justificativa técnica](docs/tecnologias/justificativa-tecnica.docx) | Decisão proposta para confirmação da equipe |
| Tecnologia sorteada: Trello | [Uso do Trello](docs/gestao/uso-do-trello.docx) | Documento fornecido pela equipe |
| Visualização das telas | [Protótipo interativo](prototipo/index.html) | Demonstração em HTML |

Os documentos originais foram preservados em Word. A proposta textual de estrutura das telas e o documento específico de plataforma e tecnologias poderão ser acrescentados quando disponibilizados pela equipe.

## Escopo da demonstração

- Comunicação por texto, cartões e frases prontas; áudio conforme suporte do navegador.
- Preferências de acessibilidade, como texto ampliado, alto contraste e rotas sem escadas.
- Consulta de locais e navegação com pontos de referência e beacons BLE simulados.
- Solicitação e acompanhamento demonstrativo de assistência.
- Saída de emergência simulada e painel demonstrativo do shopping.

Os dados são fictícios. Não há integração operacional com shopping, beacons físicos ou equipe real de atendimento. A emergência é uma simulação. O reconhecimento de voz depende do navegador, das permissões e do serviço utilizado pela plataforma. A área de Libras informa uma possibilidade futura de atendimento humano.

## Tecnologias propostas

| Etapa | Tecnologias |
|---|---|
| Protótipo de interface disponível | HTML, CSS e JavaScript |
| Aplicativo mobile proposto | Flutter e Dart |
| Dados do MVP proposto | Dados locais e simulações |
| Evolução futura | API Spring Boot e PostgreSQL, conforme validação da equipe |
| Organização das atividades | Trello |

## Pontos a alinhar

Os documentos registram decisões em aberto, incluindo a entrada de OCR no MVP, o motor de rotas e o comportamento de áudio na emergência. A documentação de requisitos v0.4 também mantém referências às 11 telas iniciais, embora tenha sido ampliada para 13. Esses pontos devem ser revisados pela equipe antes da versão definitiva.

## Organização do repositório

| Caminho | Conteúdo |
|---|---|
| `docs/requisitos/` | Requisitos do sistema |
| `docs/arquitetura/` | Arquitetura proposta |
| `docs/tecnologias/` | Justificativa tecnológica |
| `docs/gestao/` | Uso do Trello |
| `prototipo/` | Protótipo interativo |
