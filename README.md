# Acessa+ — Acessibilidade que conecta pessoas

Projeto da equipe **Charmander** para o hackathon 2026. Três pilares: **Comunicação Universal**, **Navegação Viva** e **Ajuda+**, para reduzir barreiras de comunicação e mobilidade em shopping centers.

## Estado atual

Revisão: 14/11/2026. Base versionada analisada: `2a05442`. Alterações locais de interface em desenvolvimento não são consideradas entregas concluídas.

| Recurso | Flutter |
|---|---|
| Boas-vindas e preferências combináveis | Implementado |
| Texto ampliado, alto contraste e movimento reduzido | Implementado; validação assistiva manual pendente |
| Salvar, restaurar e apagar preferências | Implementado localmente |
| Busca de destinos e filtro por piso | Implementado |
| Rotas sem escadas e preferência por elevador | Implementado sobre dados fictícios |
| Até cinco paradas, reordenação e remoção | Implementado |
| Navegação por etapas, bússola e mapa interativo | Implementado com localização simulada |
| Comunicação Universal e conversa | Planejado no Flutter; demonstrado no HTML |
| Ajuda+ e acompanhamento | Planejado no Flutter; demonstrado no HTML |
| Home, emergência e painel | Planejado no Flutter; demonstrado no HTML |
| OCR | Decisão de escopo pendente |

“Implementado” indica presença no código, não homologação ou certificação de acessibilidade.

## Executar

Pré-requisitos: Flutter com Dart compatível com `^3.13.4`, Git e Chrome ou dispositivo Android configurado.

```powershell
git clone https://github.com/luisacastro-max/Charmander.git
cd Charmander/app
flutter pub get
flutter run -d chrome
```

Para Android, use o identificador retornado por `flutter devices`. Consulte o [guia de execução](docs/desenvolvimento/execucao.md) para testes e build web.

## Documentação

- [Índice completo e documentos originais](docs/README.md)
- [Escopo e requisitos atuais](docs/requisitos/estado-atual.md)
- [Arquitetura implementada](docs/arquitetura/arquitetura-atual.md)
- [Dicionário de dados](docs/dados/dicionario-de-dados.md)
- [Plano de validação](docs/qa/plano-de-validacao.md)
- [Pendências priorizadas](docs/backlog/pendencias.md)
- [Roteiro de demonstração](docs/entrega/roteiro-demonstracao.md)
- [Contribuição e fluxo Git](CONTRIBUTING.md)

## Organização

| Caminho | Conteúdo |
|---|---|
| `app/` | Flutter, assets e testes |
| `docs/` | Documentação atual, proposta original e evidências |
| `prototipo/` | Referência HTML/CSS/JavaScript |

## Protótipo e limites

Baixe [prototipo/index.html](prototipo/index.html) e abra no navegador. Ele demonstra fluxos ainda ausentes no Flutter e usa dados próprios. Não é o build web do aplicativo.

Shopping, distâncias e eventos BLE são fictícios. A aparência de GPS não representa localização física, GPS interno, sensor magnético ou beacons reais. Nenhuma equipe real é acionada. Spring Boot e PostgreSQL são evoluções futuras.

Os Word registram a proposta inicial de 13 telas. Consulte os documentos atuais e o [registro de mudanças](docs/backlog/mudancas-de-escopo.md) para diferenciar proposta e implementação.