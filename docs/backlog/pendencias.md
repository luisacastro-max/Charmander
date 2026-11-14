# Pendências e evolução

Revisão: 14/11/2026. Referência publicada: edbc8e9 / merge 4cb0ea1. Prioridades são propostas de planejamento.

## Entregas já presentes no fonte

Cartão de frases traduzidas e respostas, Ajuda+ com revisão/acompanhamento e último metro demonstrativo já estão implementados. Isso não comprova validação assistiva ou operação real.

## Em desenvolvimento nesta etapa (em validação)

**Rota adaptada à forma de circular** — pedido do mentor. Rastreabilidade: RF03, RF12–RF15, RF18, RF48, RN01–RN04, RNF13. Cenários: [rota-adaptada.feature](../qa/rota-adaptada.feature).

História: como visitante que circula sobre rodas ou com apoio, quero que o app troque a rota mais usada (escada rolante) por um caminho com elevador e mostre o desvio, para chegar à Praça de Alimentação sem degraus e sabendo quanto a mais vou percorrer.

| Item | Critério de aceite resumido | Evidência esperada |
|---|---|---|
| Dados fictícios da Praça de Alimentação | Sem restrições, a rota usa escada rolante; com "Rotas sem escadas", usa elevador e é mais longa | Teste de rotas + captura das duas rotas |
| Comparação “Rota mais usada × Rota adaptada para você” | Mostra em texto o que evitou, o que substitui e + metros/+ minutos; nada só por cor | Teste de widget + captura + leitura com TalkBack |
| Atalho “Como você vai circular hoje?” | “Sobre rodas” e “Com apoio” só ligam “Rotas sem escadas” e “Preferência por elevadores”; a opção não é salva | Teste de preferências salvas + revisão do armazenamento local |
| Simulação “elevador em manutenção” | Identificada como simulação; recalcula; sem caminho, informa sem tirar a restrição e oferece Ajuda+ | Teste de widget + captura do aviso |

Status: em validação. Só considerar entregue com testes executados (commit registrado) e roteiro conferido no aparelho.

Limitações conhecidas (pendências futuras, prioridades propostas):

| Prioridade | Trabalho | Resultado esperado |
|---|---|---|
| Alta | Validar a rota adaptada com pessoas usuárias de cadeira de rodas, carrinho e apoio | Registro de compreensão do desvio; resultados como subsídio à equipe |
| Média | Dados reais de largura de porta, inclinação de rampa, piso e desníveis | Hoje inexistentes; trechos seguem “Não informado” até haver levantamento |
| Média | Status real de elevadores e escadas rolantes | Hoje só simulação manual; integração exige fonte oficial do shopping |
| Média | Segundo elevador ou rota alternativa sem escadas nos dados | Hoje a manutenção do único elevador deixa o 2º piso sem caminho compatível |
| Baixa | Tempos de percurso por forma de circular | Hoje minutos são estimativa fixa, não medição |
| A definir | Registrar a mudança de fluxo (atalho de circulação) em mudancas-de-escopo.md | Proposta de MUD-03 para aprovação |

## Em desenvolvimento nesta etapa: mapa colaborativo de alertas (PROPOSTA)

Novo escopo ainda não aprovado: [MUD-04 (proposta)](mudancas-de-escopo.md). Requisitos sugeridos RF-A01–RF-A08 e RN-A01–RN-A07 em [estado-atual.md](../requisitos/estado-atual.md). Cenários: [alertas-comunidade.feature](../qa/alertas-comunidade.feature). Prioridades são propostas.

| # | História (objetivo para o visitante) | Requisitos | Critério de aceite resumido | Evidência esperada |
|---|---|---|---|---|
| A1 | Como visitante, quero avisar um problema que encontrei, para que outras pessoas não sejam surpreendidas | RF-A01, RF-A02, RN-A06, RN01 | Dado o mapa ou a rota, quando toco em “Reportar problema”, escolho tipo, confirmo ponto e andar e envio, então o marcador aparece no lugar certo; descrição opcional limitada a 140 caracteres; nenhum dado pessoal pedido | Teste de widget do formulário + captura + revisão do JSON salvo |
| A2 | Como pessoa que usa leitor de tela, quero escolher o local sem arrastar a planta | RF-A02 | Lista “Perto de” define o ponto; envio concluído só com TalkBack | Roteiro manual com TalkBack registrado |
| A3 | Como visitante, quero ver alertas novos sem recarregar | RF-A03 | Relato feito na sessão A aparece na sessão B do mesmo andar em até ~5 s | Validação manual com duas sessões (vídeo ou capturas com horário) |
| A4 | Como visitante, quero entender um alerta e saber se ainda vale | RF-A04, RF-A07 | Card mostra tipo, descrição, local, andar, horário, situação e “não verificado”; bloqueio e aviso diferem por forma e texto | Teste de widget + captura em alto contraste |
| A5 | Como visitante, quero confirmar ou dar como resolvido, para o mapa ficar atualizado | RN-A02, RN-A03, RN-A05 | “Ainda está aqui” renova prazo e zera votos; resolve com min(2, confirmações) votos de sessões distintas; mesma sessão não vota duas vezes | Testes de regra (domínio e servidor) |
| A6 | Como visitante, quero que relatos repetidos não encham o mapa | RN-A04, RF-A07 | Mesmo tipo e andar a até 30 unidades vira confirmação; marcadores próximos agrupados; filtro por tipo e andar | Testes de regra + captura do agrupamento |
| A7 | Como pessoa que evita escadas, quero que a rota desvie de um elevador parado ou me diga claramente que não há caminho | RF-A05, RN-A01, RN04, RF36 | Bloqueio retira o trecho; aviso encarece; sem alternativa: explicação com o alerta causador, restrição mantida e “Pedir ajuda”; nunca sugere escada | Testes de rotas com alertas + captura da mensagem |
| A8 | Como visitante navegando, quero saber de um alerta novo no meu caminho | RF-A06 | Aviso e oferta “Recalcular rota” só para trechos ainda não percorridos; não repete para o mesmo alerta | Teste de widget da navegação + validação com duas sessões |
| A9 | Como visitante, quero saber quando os alertas são só uma simulação ou estão desatualizados | RF-A08, RN-A07 | Sem servidor, “Simulação” visível no mapa, formulário e card; erro de envio guarda o texto e oferece “Tentar de novo”; erro de conexão avisa e mantém os últimos alertas | Teste de widget dos estados + captura na publicação estática |

Status: em desenvolvimento. Só considerar entregue com testes executados (commit registrado) e validação com duas sessões conferida.

Pendências reais do mapa de alertas (prioridades propostas):

| Prioridade | Trabalho | Por que importa |
|---|---|---|
| Alta | Moderação e prevenção de abuso | Um único relato falso de “Elevador fora de serviço” pode bloquear por 12 h a única rota sem escadas e empurrar quem usa cadeira de rodas para o “Pedir ajuda”. Sem moderação, também é possível publicar texto ofensivo ou dados pessoais na descrição. Avaliar: limite por sessão, revisão por equipe do shopping, bloqueio só após 2 relatos, denúncia de conteúdo |
| Alta | Autenticação ou outra proteção contra votos repetidos | A sessão não é salva: recarregar a página gera nova sessão e permite votar de novo (“Ainda está aqui” ou “Já foi resolvido”). Aceitável na demonstração, não em produção |
| Alta | Hospedagem do servidor | A publicação estática na Vercel não tem API: lá o app sempre roda em simulação local. Para compartilhar entre aparelhos fora da rede local é preciso hospedar a API (futura API Spring Boot) |
| Alta | Avaliação de Privacidade (LGPD) e Segurança da Informação antes de qualquer uso fora da demonstração | Descrição livre pode conter dados pessoais; endereço IP e horários chegam ao servidor; definir retenção e exclusão dos relatos; só usar ferramentas e hospedagem homologadas (chamado na Central de Serviços/JIRA quando necessário) |
| Alta | Validação com pessoas usuárias reais (cadeira de rodas, baixa visão, leitor de tela, neurodivergentes) | Confirmar se os tipos, prazos, avisos e mensagens de “sem caminho” são compreensíveis e úteis. Resultados são subsídio à decisão da equipe |
| Média | Revisão humana das traduções (pt/en/es) dos tipos, avisos e mensagens | Textos de segurança mal traduzidos podem confundir; tradução automática não substitui revisão |
| Média | Calibrar prazos, raio de duplicado (30) e raios de efeito com dados reais | Valores atuais são escolhas de demonstração em unidades da planta fictícia |
| Média | Relação com status oficial de equipamentos do shopping | Relato da comunidade não deve contradizer informação oficial sem deixar claro qual é qual |
| Baixa | Atualização por envio do servidor (em vez de consulta a cada ~3 s) | Menos consumo de bateria e rede em produção |

## Próximas verificações e melhorias

| Prioridade | Trabalho | Resultado esperado |
|---|---|---|
| Alta | Validar build e testes no aparelho da apresentação | Evidência com commit, versões e resultado |
| Alta | Validar cartão, assistência e último metro com leitor de tela | Fluxo compreensível sem depender do visual |
| Alta | Corrigir instrução de escada rolante em descida | Texto coerente nos dois sentidos |
| Média | Ordenar escritas e tratar falhas de preferências | Estado salvo coerente com última escolha/exclusão |
| Média | Recuperar erro de carga JSON | Nova tentativa sem cache permanente de erro |
| Média | Finalizar e validar voz e traduções locais | Publicar somente após conferir idioma e dispositivo |
| Média | Completar Home, retomada e controles de navegação | Contexto previsível entre recursos |
| Média | Barreira e rota alternativa | Preservar restrições e permitir escolha |
| Média | Card “Neste local” | Ação contextual apenas por escolha do visitante |
| Média | Revisar Word e rastreabilidade | Alinhar fluxo, 13 telas e status |
| Baixa | Separar enum de idioma da apresentação | Reduzir acoplamento do domínio |
| A definir | Chat livre, voz para texto, OCR, emergência e painel | Decisão de escopo e requisitos antes da implementação |

O último metro usa cena fixa e não resolve OCR. API, banco e beacons reais são evolução, sem dependência para avaliar o MVP. Cada tarefa deve ter responsável, requisito, critério de aceite e evidência.