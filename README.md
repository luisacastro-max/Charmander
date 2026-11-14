# Acessa+ — Acessibilidade que conecta pessoas

Aplicativo da equipe **Charmander**, desenvolvido para o hackathon 2026. Reúne comunicação acessível, orientação dentro de um shopping demonstrativo e solicitação de ajuda.

## Entrega para avaliação

**Comece pelo [guia de avaliação](docs/entrega/guia-avaliacao.md)** e pela [documentação técnica consolidada](docs/documentacao-tecnica.md).

| Material | Localização |
|---|---|
| Explicação do projeto, arquitetura, tecnologias e funcionamento | [Documentação técnica](docs/documentacao-tecnica.md) |
| Código-fonte Flutter | [app/lib](app/lib) |
| Assets e dados fictícios | [app/assets](app/assets) |
| Testes automatizados | [app/test](app/test) |
| Instalação, execução e build | [Guia de execução](docs/desenvolvimento/execucao.md) |
| Índice dos documentos | [docs/README.md](docs/README.md) |
| Protótipo HTML de referência | [prototipo/index.html](prototipo/index.html) |

## O que o aplicativo oferece

- Preferências combináveis, sem cadastro ou diagnóstico obrigatório.
- Texto ampliado, alto contraste e redução de movimento.
- Busca de destinos, origem simulada e planejamento de até cinco paradas.
- Rotas com restrição de escadas e preferências de elevador e movimento.
- Navegação por pontos simulados, com instruções textuais e mapa interativo.
- Cartão de ajuda com frases em português, inglês e espanhol, respostas por toque e modo frente a frente.
- Ajuda+ com pedido, revisão, acompanhamento demonstrativo e cancelamento.
- “Último metro”: procura de objetos em uma cena fictícia, com sinais visuais e hápticos.

## Executar

Requer Flutter com Dart compatível com `^3.13.4`, Git e Chrome ou Android configurado.

```powershell
git clone https://github.com/luisacastro-max/Charmander.git
cd Charmander/app
flutter pub get
flutter run -d chrome
```

Para testar: `flutter analyze` e `flutter test` em `app/`. Para build web: `flutter build web --release`. Instruções completas e limitações de ambiente estão no guia de execução.

## Versão documentada

Revisão de 14/11/2026 sobre o código `edbc8e9`, incorporado à main por `4cb0ea1`. A presença no código não representa homologação nem certificação de acessibilidade.

Síntese de voz com flutter_tts, traduções ampliadas da interface e alterações visuais estavam em desenvolvimento local na revisão. Não fazem parte da versão publicada usada como referência e não são pré-requisitos desta entrega.

## Organização

| Diretório | Responsabilidade |
|---|---|
| app/ | Aplicativo, plataformas, dependências e testes |
| docs/ | Documentação, propostas originais e evidências |
| prototipo/ | Referência HTML independente do Flutter |

Consulte o [guia de contribuição](CONTRIBUTING.md) para branches e pull requests.

## Limites

Shopping, distâncias, BLE e atendimento são demonstrativos. A aparência de GPS não implica localização física. “Último metro” não acessa câmera nem reconhece objetos reais. Não há envio de pedidos a funcionários, backend, banco remoto ou tradução automática de Libras.

Home completa, conversa livre, voz para texto, emergência e painel permanecem evoluções ou demonstrações do HTML. Os Word são propostas históricas; o [estado atual](docs/requisitos/estado-atual.md) identifica o escopo publicado.