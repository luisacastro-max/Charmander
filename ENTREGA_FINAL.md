# Entrega final — HackaRun 2026

**Projeto:** Acessa+ — Acessibilidade que conecta pessoas  
**Equipe:** Charmander  
**Revisão:** 14/11/2026  
**Código do MVP:** 0500d9d, integrado à main por 54786c3

## Materiais exigidos

| Item da entrega | Material disponível |
|---|---|
| 1. MVP funcional | Aplicativo publicado na Vercel — link a ser informado pela equipe |
| 2. Repositório e fonte | [Repositório público](https://github.com/luisacastro-max/Charmander), [fonte](app/lib/) e [testes](app/test/) |
| 3. Documentação técnica | [Projeto, arquitetura, tecnologias e funcionamento](docs/documentacao-tecnica.md) |
| 4. Instruções de execução | [Instalação, configuração, execução e build](docs/desenvolvimento/execucao.md) |

A versão entregue é o aplicativo Flutter, não o protótipo HTML. O código está organizado por funcionalidades, domínio, dados e componentes compartilhados. Não é necessário cadastro para experimentar.

## O que demonstrar no MVP

- Preferências locais: texto ampliado, alto contraste, redução de estímulos e mobilidade.
- Pesquisa de destino, escolha da origem simulada e rota com até cinco paradas.
- Instruções e mapa por piso, progresso e chegada por eventos BLE simulados.
- Cartão de comunicação com frases traduzidas, respostas e modo frente a frente.
- Ajuda+: necessidade, local, revisão, confirmação, estados demonstrativos e cancelamento.
- Interface em português, inglês e espanhol nos textos cadastrados, com retorno ao português quando não houver tradução.
- Texto para voz conforme a escolha do visitante e suporte do navegador/dispositivo.
- Mapa colaborativo: registrar, confirmar e indicar resolução de ocorrências; impacto nas rotas conforme regras.
- Último metro: procura de objetos em cena fictícia, com direção e sinais simulados.

## Reproduzir rapidamente

Instale Git e Flutter **3.47.5** (Dart **3.13.4**, versões identificadas no ambiente), com Chrome. O pubspec exige Dart compatível com ^3.13.4.

```powershell
git clone https://github.com/luisacastro-max/Charmander.git
cd Charmander
git rev-parse HEAD
cd app
flutter pub get
flutter run -d chrome
```

Sem API disponível, o app usa alertas simulados locais e informa esse modo. Isso permite avaliar o fluxo sem infraestrutura externa.

## Avaliar alertas entre dois navegadores

Com Node.js 18 ou superior e Flutter instalados:

```powershell
# Na pasta app:
flutter build web --release
cd ..
node .claude/serve-web.js 8097 localhost
```

Abra http://localhost:8097 em dois navegadores ou perfis. A API na mesma origem é detectada pelo aplicativo. Cadastre um alerta em um navegador e confira o outro após a atualização periódica de aproximadamente três segundos.

O servidor usa JSON local e é de demonstração, sem autenticação ou moderação. Não é um backend operacional de shopping. Veja a configuração de aparelhos e CORS no [guia completo](docs/desenvolvimento/execucao.md).

## Ordem sugerida para a banca

1. Ajustar acessibilidade e idioma.
2. Buscar a Praça de Alimentação e iniciar uma rota sem escadas.
3. Adicionar uma parada e simular chegadas.
4. Mostrar cartão e resposta de outra pessoa.
5. Pedir ajuda, revisar e acompanhar a simulação.
6. Registrar ocorrência e verificar o modo local/compartilhado.
7. Mostrar a cena fictícia do último metro.

## Acesso ao MVP na Vercel

**Link do aplicativo:** a ser informado pela equipe.

O aplicativo será avaliado pelo endereço da Vercel. O código-fonte e as instruções locais permanecem disponíveis para reproduzir a execução.

## Evidências técnicas

Consulte o [registro de validação](docs/qa/validacao-entrega-final.md). Análise estática e build web de produção foram concluídos; o registro também identifica testes de execução bloqueados pelo ambiente.

## Limites declarados

BLE, shopping, distâncias, assistência e cena do último metro são demonstrativos. Não há câmera real, OCR, equipe acionada ou tradução automática de Libras. Voz depende do motor instalado. Compartilhamento de alertas exige a API; hospedagem apenas estática mantém a simulação local se a API não estiver configurada.

Esta organização prepara os materiais técnicos. Não realiza envio em formulário ou canal externo da competição e não comprova horário de submissão.
