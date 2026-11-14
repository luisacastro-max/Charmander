# Guia de avaliação — Acessa+

## Materiais

| Item solicitado | Onde avaliar |
|---|---|
| Explicação do projeto e problema | [Documentação técnica, seções 1–2](../documentacao-tecnica.md) |
| Arquitetura | [Arquitetura atual](../arquitetura/arquitetura-atual.md) |
| Tecnologias | [Documentação técnica, seção 3](../documentacao-tecnica.md) |
| Funcionamento | [Documentação técnica, seções 5–7](../documentacao-tecnica.md) |
| Código-fonte organizado | [app/lib](../../app/lib) |
| Dependências | [pubspec.yaml](../../app/pubspec.yaml) e [pubspec.lock](../../app/pubspec.lock) |
| Dados e fontes | [app/assets](../../app/assets) |
| Testes | [app/test](../../app/test) |
| Execução | [Guia de execução](../desenvolvimento/execucao.md) |
| Limites e validação | [Plano de validação](../qa/plano-de-validacao.md) |

Repositório público: https://github.com/luisacastro-max/Charmander

Código de referência: edbc8e9, integrado à main por 4cb0ea1. Na avaliação de outra revisão, registrar o SHA obtido com git rev-parse HEAD.

## Preparar e executar

Clonar o repositório, entrar em app/, instalar dependências com flutter pub get e executar flutter run -d chrome. O SDK Dart precisa atender ^3.13.4. Android exige SDK e aparelho/emulador configurado.

Não é necessário backend, banco de dados, login, chave de API ou beacon físico. O fonte está separado de builds e caches, que não são entregáveis versionados.

## Jornada sugerida

1. Ajustar texto, contraste e preferência por rota sem escadas.
2. Buscar a Praça de Alimentação e conferir percurso.
3. Adicionar ou reordenar paradas e iniciar a navegação.
4. Avançar pelos pontos simulados e conferir mapa e chegada.
5. Abrir o cartão de ajuda; selecionar frase, idioma e resposta.
6. Abrir Ajuda+, corrigir local, revisar, confirmar e avançar estados demonstrativos.
7. Retomar o percurso ou explorar o “último metro” com a cena fictícia.
8. Conferir a Galeria do Mezanino sem rota compatível com a restrição de escadas.

## Verificar qualidade

Executar flutter analyze e flutter test. Registrar data, commit, ambiente e resultados. Testar manualmente com leitor de tela, escala ampliada e movimento reduzido.

Esta organização documental não declara testes recém-aprovados nem acessibilidade integral. O protótipo HTML é referência separada; não usar suas funções como evidência de implementação Flutter.

## Situação das mudanças locais

Voz, traduções ampliadas e refinamentos visuais estavam em desenvolvimento local durante a revisão. Não integram automaticamente a versão pública descrita. Avaliar o commit publicado, não arquivos locais sem identificação de versão.
