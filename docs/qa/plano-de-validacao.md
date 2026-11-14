# Plano de testes e validação

Base publicada: 0500d9d, integrado à main por 54786c3. Revisão documental: 14/11/2026.

## Automação

Executar em app/: `flutter analyze` e `flutter test`. Para cobertura opcional: `flutter test --coverage`.

| Arquivo em app/test/ | Área |
|---|---|
| widget_test.dart | Boas-vindas, preferências, tema e semântica |
| destino_test.dart | Busca, filtro e origem |
| navegacao_test.dart | Paradas, avanço e mapa |
| cartao_ajuda_test.dart | Frases traduzidas, respostas e frente a frente |
| ajuda_test.dart | Pedido, revisão, estados e retorno ao percurso |
| encontrar_test.dart | Cena fictícia, gestos e sinais |
| data/dados_test.dart | Integridade dos JSON |
| data/preferences_store_test.dart | Persistência e exclusão |
| data/rotas_test.dart | Restrições e cálculo |
| data/viagem_test.dart | Paradas e estado de navegação |

Os arquivos .feature são especificações BDD. Não há runner Gherkin configurado; testes Dart fazem a automação relacionada.

## Validação manual

- Usar TalkBack e, quando houver dispositivo, VoiceOver.
- Conferir foco, ordem, rótulos, anúncios e teclado no navegador.
- Testar fonte ampliada com escala do sistema em telas estreitas.
- Conferir alto contraste e movimento reduzido.
- Salvar, reabrir e apagar preferências.
- Calcular rota sem escadas e demonstrar incompatibilidade do Mezanino.
- Adicionar, reordenar e remover paradas; confirmar limite de cinco.
- Avançar por pontos, conferir pisos, zoom e recentralização.
- Selecionar frases, idioma do leitor, respostas e frente a frente.
- Revisar local e pedido, avançar estados, cancelar e retomar percurso.
- Testar último metro com cena e direção simuladas, sem pressupor câmera real.
- Conferir recursos locais sem conexão depois de disponibilizar o app, sem presumir instalação web offline.

## Mapa colaborativo de alertas (PROPOSTA, em desenvolvimento)

Cenários: [alertas-comunidade.feature](alertas-comunidade.feature). Nomes dos testes Dart a confirmar com o front-end e o back-end quando forem entregues; esperam-se testes das regras (validade, resolução, duplicado, efeito nas rotas) e de widget (formulário, card, estados, aviso na navegação).

**Ambiente para duas sessões:**

- Build web gerado e servido pela configuração `acessa-web-celular` (porta 8098, rede local), com a API de alertas ativa (conferir com o back-end).
- Sessão A: navegador do computador. Sessão B: celular na mesma Wi-Fi (`http://<IP do computador>:8098`) ou segunda janela do navegador.
- Antes de começar, confirmar que nenhuma sessão mostra o aviso de simulação. Registrar o commit e o horário.

**Roteiro de validação manual:**

| # | Passo | Resultado esperado | Evidência |
|---|---|---|---|
| 1 | A relata “Obstáculo no caminho” no Térreo | Marcador aparece em B em até ~5 s, sem recarregar | Capturas com horário ou vídeo curto |
| 2 | B troca para outro andar | Marcador do Térreo não aparece | Captura |
| 3 | B abre o card | Tipo, descrição, local, andar, horário, situação e “não verificado” | Captura |
| 4 | A relata o mesmo tipo a poucos passos | Não cria marcador novo; confirmações sobem | Captura do card |
| 5 | A relata “Elevador fora de serviço”; B (sem escadas) pede rota ao 2º piso | Explicação de “sem caminho”, restrição mantida, “Pedir ajuda”; nenhuma escada sugerida | Captura |
| 6 | B navega e A relata alerta num trecho à frente | B recebe aviso e oferta de recálculo, uma vez só | Captura ou vídeo |
| 7 | B toca “Já foi resolvido” em alerta com 1 confirmação | Resolvido nas duas sessões; rota volta ao normal | Capturas |
| 8 | Alerta com 2 ou mais confirmações: mesma sessão vota duas vezes | Só conta um voto; continua ativo | Captura do card |
| 9 | Desligar o servidor com o app aberto | Aviso de conexão; alertas anteriores continuam visíveis; volta sozinho ao religar | Capturas |
| 10 | Enviar relato com servidor desligado | Erro em texto, conteúdo preservado, “Tentar de novo” funciona ao religar | Capturas |
| 11 | Abrir a publicação estática (Vercel) ou sem servidor | “Simulação” visível no mapa, formulário e card | Captura |
| 12 | Repetir 1, 3 e 5 com TalkBack, texto ampliado e alto contraste | Tudo anunciado, inclusive “não verificado” e “simulação”; lista “Perto de” funciona; bloqueio e aviso distinguíveis sem cor | Registro do roteiro com leitor de tela |

Expiração (horas) não é prática de validar manualmente: conferir por testes automatizados das regras. Itens não validáveis nesta etapa: moderação, autenticação, hospedagem pública e validação com pessoas usuárias (ver [pendências](../backlog/pendencias.md)).

## Evidências e resultado desta revisão

Registrar data, commit, responsável, dispositivo, sistema, versões Flutter/Dart, comandos e resultados. Capturas históricas não comprovam o build atual. Cobertura de linhas não equivale a requisitos integralmente atendidos.

A revisão final inclui análise estática e tentativas de execução registradas em [validação da entrega](validacao-entrega-final.md). Voz e i18n agora integram a base publicada.

Antes da apresentação, executar o fluxo no aparelho escolhido e registrar falhas. Não declarar certificação ou acessibilidade integral apenas com testes de widgets.