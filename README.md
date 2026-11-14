# Acessa+ — Acessibilidade que conecta pessoas

Projeto da equipe **Charmander** para o HackaRun 2026: comunicação acessível, navegação em shopping demonstrativo e ajuda ao visitante.

## Entrega final

**[Acesse os quatro itens da entrega final](ENTREGA_FINAL.md).**

| Item | Material |
|---|---|
| MVP na Vercel | Link a ser informado pela equipe |
| Código-fonte | [app/lib](app/lib/) |
| Documentação técnica | [Projeto, arquitetura, tecnologias e funcionamento](docs/documentacao-tecnica.md) |
| Instalação e execução | [Guia reproduzível](docs/desenvolvimento/execucao.md) |
| Testes e evidências | [Testes](app/test/) e [validação da entrega](docs/qa/validacao-entrega-final.md) |

## Funcionalidades

Preferências locais, contraste e texto ampliado; pesquisa de destinos; rotas com até cinco paradas; mapa e avanço por beacons simulados; cartão de comunicação e respostas; Ajuda+ com revisão/acompanhamento; idiomas pt/en/es e síntese de voz conforme suporte; mapa colaborativo de ocorrências; último metro em cena fictícia.

A interface indica quando os alertas estão simulados localmente. Compartilhamento entre navegadores exige API: o servidor de demonstração está incluído.

## Executar

```powershell
git clone https://github.com/luisacastro-max/Charmander.git
cd Charmander/app
flutter pub get
flutter run -d chrome
```

Ambiente identificado: Flutter 3.47.5 / Dart 3.13.4. Requer Chrome ou ambiente Android. [Configuração completa e modo compartilhado](docs/desenvolvimento/execucao.md).

## Organização

| Diretório | Responsabilidade |
|---|---|
| app/lib/features/ | Telas por funcionalidade |
| app/lib/domain/ | Modelos e regras |
| app/lib/data/ | Repositórios e dados |
| app/lib/core/ | Componentes e voz |
| app/lib/app/ | Aplicação, tema, rotas e traduções |
| app/assets/ | JSON e fontes |
| app/test/ | Testes automatizados |
| .claude/serve-web.js e .claude/api-ocorrencias.js | Servidor de demonstração e API |
| docs/ | [Documentação e propostas originais](docs/README.md) |
| prototipo/ | Referência HTML independente do Flutter |

Código-base desta entrega: 0500d9d, integrado à main por 54786c3. Consulte [CONTRIBUTING.md](CONTRIBUTING.md) para colaboração.

## Limites

Shopping, BLE, distâncias, assistência e cena do último metro são demonstrativos. Não há câmera real, OCR, localização física, atendimento acionado ou tradução automática de Libras. API Node é demonstrativa, sem autenticação ou moderação. Spring Boot/PostgreSQL são evolução futura.

O [guia de avaliação](docs/entrega/guia-avaliacao.md) apresenta a jornada. O HTML não comprova funcionalidades do Flutter.
