# language: pt
# Mapa colaborativo de alertas (relatos da comunidade) — PROPOSTA / novo escopo, 14/11/2026
# Rastreabilidade: RF-A01 a RF-A08 e RN-A01 a RN-A07 (numeração PROPOSTA, ver docs/requisitos/estado-atual.md);
#   relaciona-se a RF12–RF15, RF17–RF22, RF36 (Ajuda+), RF45, RF48, RN01, RN02, RN04, RNF13.
# Situação: em desenvolvimento. Rótulos de tela são prováveis e podem ser ajustados pelo front-end.
# Coordenadas em "unidades da planta" (as mesmas dos dados fictícios do shopping).
#
# História
#   Como visitante do shopping,
#   quero avisar e ser avisado de problemas no caminho (piso molhado, elevador parado, passagem interditada),
#   para escolher um percurso seguro e possível para mim sem depender de encontrar a barreira na hora.
#
# Princípios verificados: relato é da comunidade e NÃO verificado; ninguém se identifica nem declara deficiência
# (RN01); o app nunca sugere escada a quem escolheu "Rotas sem escadas" (RN04); simulação aparece identificada;
# bloqueio e aviso não se distinguem só por cor; o leitor de tela consegue fazer tudo sem tocar na planta.
#
# Validades (renovadas a cada "Ainda está aqui"):
#   piso molhado 2 h | passagem interditada 8 h | obstáculo 2 h | elevador fora de serviço 12 h
#   escada rolante parada 12 h | rampa bloqueada 6 h | local muito cheio 1 h | outro problema 3 h
# Efeito nas rotas:
#   BLOQUEIA: passagem interditada, elevador fora de serviço, rampa bloqueada
#   AVISO (encarece o trecho): piso molhado, obstáculo, escada rolante parada, local muito cheio, outro problema

Funcionalidade: Mapa colaborativo de alertas

  Contexto:
    Dado que o app está aberto no shopping demonstrativo
    E que estou no mapa ou em uma rota

  # ---------- Registrar ----------

  Cenário: Registrar uma ocorrência em ponto e andar (RF-A01, RF-A02)
    Quando toco em "Reportar problema"
    E escolho o tipo "Piso molhado ou escorregadio"
    E confirmo o ponto na mini-planta do "Térreo"
    E escrevo a descrição "Perto do bebedouro"
    E toco em "Enviar"
    Então vejo a confirmação de que o alerta foi publicado
    E o marcador aparece no ponto e no andar escolhidos
    E o card informa "Relato da comunidade, não verificado"

  Cenário: Ajustar o ponto quando a posição sugerida está errada (RF-A02)
    Dado que a mini-planta sugere minha posição atual
    Quando arrasto o ponto ou troco o andar para "Mezanino"
    Então o alerta é registrado no ponto e andar que eu confirmei, não na posição sugerida

  Cenário: Escolher o local sem usar a planta, pelo leitor de tela (RF-A02, acessibilidade)
    Dado que o TalkBack está ativo
    Quando abro "Reportar problema"
    Então encontro a lista "Perto de" com pontos de referência do andar, como "Perto de Elevador"
    E escolher um item da lista define o ponto do alerta
    E consigo concluir o envio sem arrastar nada na planta

  Esquema do Cenário: Os oito tipos estão disponíveis
    Quando abro "Reportar problema"
    Então posso escolher o tipo "<tipo>"

    Exemplos:
      | tipo                           |
      | Piso molhado ou escorregadio   |
      | Passagem interditada           |
      | Obstáculo no caminho           |
      | Elevador fora de serviço       |
      | Escada rolante parada          |
      | Rampa bloqueada                |
      | Local muito cheio              |
      | Outro problema                 |

  Cenário: Descrição é opcional e limitada a 140 caracteres (RF-A01, RN-A06)
    Quando abro "Reportar problema"
    Então posso enviar sem descrição
    E o campo de descrição não aceita mais de 140 caracteres
    E vejo quantos caracteres restam, em texto
    E vejo o aviso "Não escreva nomes, telefones ou outros dados pessoais"

  Cenário: Nenhum dado pessoal é pedido para relatar (RN-A06, RN01, RNF13)
    Quando concluo um relato
    Então nenhuma tela pediu nome, e-mail, telefone, login ou deficiência
    E o relato guarda só tipo, ponto, andar, descrição, horários, contagens e situação

  # ---------- Ver e receber ----------

  Cenário: Outra sessão recebe o marcador automaticamente (RF-A03)
    Dado que a sessão A e a sessão B estão no mesmo shopping, no mapa do "Térreo"
    Quando a sessão A registra "Obstáculo no caminho" no Térreo
    Então em até cerca de 5 segundos o marcador aparece na sessão B
    E a sessão B não precisou recarregar a página nem tocar em atualizar

  Cenário: Marcador só aparece no andar correspondente (RF-A03, RF-A07)
    Dado que existe um alerta ativo no "2º piso"
    Quando estou vendo o mapa do "Térreo"
    Então o marcador não aparece no Térreo
    E ao trocar para o "2º piso" o marcador aparece

  Cenário: Tocar no marcador mostra os detalhes (RF-A04)
    Dado que existe um alerta ativo de "Elevador fora de serviço"
    Quando toco no marcador
    Então vejo tipo, descrição (ou "Sem descrição"), local de referência, andar, horário do relato e situação
    E vejo "Relato da comunidade, não verificado"
    E vejo os botões "Ainda está aqui" e "Já foi resolvido"
    E vejo em texto se o alerta bloqueia o caminho ou é só um aviso

  Cenário: Bloqueio e aviso não dependem só de cor (RF-A07, acessibilidade)
    Dado que no mapa há um alerta de "Passagem interditada" e um de "Piso molhado ou escorregadio"
    Então os marcadores têm formas diferentes para bloqueio e para aviso
    E cada marcador tem ícone do tipo
    E o leitor de tela anuncia, por exemplo, "Bloqueio: Passagem interditada, Térreo, perto de Praça de Eventos"

  Cenário: Marcadores próximos são agrupados (RF-A07)
    Dado que existem três alertas muito próximos no mesmo andar
    Quando vejo o mapa com pouco zoom
    Então vejo um marcador de grupo com o número "3" em texto
    E ao tocar no grupo vejo a lista dos três alertas

  Cenário: Filtrar por categoria e andar (RF-A07)
    Dado que existem alertas de vários tipos em vários andares
    Quando filtro só "Elevador fora de serviço" no "Mezanino"
    Então só vejo marcadores desse tipo nesse andar
    E vejo em texto quais filtros estão ativos e como limpá-los

  # ---------- Confirmar e resolver ----------

  Cenário: "Ainda está aqui" renova o prazo e zera os votos de resolvido (RN-A02, RN-A03)
    Dado um alerta ativo com 1 voto "Já foi resolvido"
    Quando outra sessão toca em "Ainda está aqui"
    Então o prazo de validade recomeça a contar a partir de agora
    E o número de confirmações aumenta em 1
    E os votos de "Já foi resolvido" voltam a zero

  Cenário: Resolver um alerta relatado por uma só pessoa (RN-A03)
    Dado um alerta ativo com 1 confirmação
    Quando uma sessão, inclusive a de quem relatou, toca em "Já foi resolvido"
    Então o alerta passa à situação "Resolvido"

  Cenário: Resolver um alerta confirmado por várias pessoas (RN-A03)
    Dado um alerta ativo com 3 confirmações
    Quando uma sessão toca em "Já foi resolvido"
    Então o alerta continua ativo
    Quando outra sessão, diferente da primeira, toca em "Já foi resolvido"
    Então o alerta passa à situação "Resolvido"

  Cenário: A mesma sessão não vota duas vezes (RN-A05)
    Dado um alerta ativo com 3 confirmações
    Quando a mesma sessão toca duas vezes em "Já foi resolvido"
    Então só um voto é contado
    E o alerta continua ativo

  Esquema do Cenário: Alerta expira pelo tipo (RN-A02)
    Dado um alerta de "<tipo>" confirmado pela última vez há <tempo>
    Então a situação é "<situação>"

    Exemplos:
      | tipo                         | tempo       | situação |
      | Local muito cheio            | 59 minutos  | Ativo    |
      | Local muito cheio            | 1 hora      | Expirado |
      | Piso molhado ou escorregadio | 2 horas     | Expirado |
      | Rampa bloqueada              | 5 horas     | Ativo    |
      | Passagem interditada         | 8 horas     | Expirado |
      | Elevador fora de serviço     | 11 horas    | Ativo    |
      | Escada rolante parada        | 12 horas    | Expirado |
      | Outro problema               | 3 horas     | Expirado |

  # ---------- Duplicado ----------

  Cenário: Relato repetido vira confirmação do existente (RN-A04)
    Dado um alerta ativo de "Piso molhado ou escorregadio" no Térreo
    Quando outra sessão relata "Piso molhado ou escorregadio" no Térreo a até 30 unidades da planta dele
    Então nenhum marcador novo é criado
    E o alerta existente ganha mais uma confirmação e tem o prazo renovado
    E a pessoa vê em texto que o problema já estava relatado e que o relato dela foi somado

  Cenário: Tipo, andar ou distância diferentes criam alerta novo (RN-A04)
    Dado um alerta ativo de "Piso molhado ou escorregadio" no Térreo
    Quando outra sessão relata "Obstáculo no caminho" no mesmo ponto
    Então um alerta novo é criado
    E o mesmo vale para o mesmo tipo em outro andar ou a mais de 30 unidades da planta

  Cenário: Alerta resolvido ou expirado não absorve relato novo (RN-A04)
    Dado um alerta "Resolvido" de "Rampa bloqueada" no Mezanino
    Quando alguém relata "Rampa bloqueada" no mesmo ponto
    Então um alerta novo e ativo é criado

  # ---------- Rotas ----------

  Cenário: Alerta de bloqueio tira o trecho da busca de rota (RF-A05, RN-A01)
    Dado um alerta ativo de "Passagem interditada" no corredor que a rota mais curta usaria
    Quando calculo uma rota até um destino depois desse corredor
    Então a rota não passa pelo trecho interditado
    E vejo em texto que a rota evitou o alerta da comunidade

  Cenário: Alerta de aviso encarece o trecho e gera aviso (RF-A05, RN-A01)
    Dado um alerta ativo de "Piso molhado ou escorregadio" no caminho mais curto
    E que existe alternativa de distância razoável
    Quando calculo a rota
    Então a rota prefere a alternativa
    E, se não houver alternativa razoável, a rota passa pelo trecho e mostra o aviso "Piso molhado" na etapa

  Cenário: Alerta novo no caminho durante a navegação oferece recálculo (RF-A06)
    Dado que estou navegando até a Praça de Alimentação
    Quando outra sessão registra "Escada rolante parada" num trecho que ainda vou percorrer
    Então vejo e ouço pelo leitor de tela um aviso sobre o alerta no meu caminho
    E posso escolher "Recalcular rota" ou "Seguir assim"
    E o aviso não volta a aparecer para o mesmo alerta

  Cenário: Alerta em trecho já percorrido não interrompe a navegação (RF-A06)
    Dado que estou navegando
    Quando surge um alerta num trecho que já percorri
    Então não recebo oferta de recálculo

  Cenário: Sem rota alternativa acessível (RF-A05, RN04, RN-A01)
    Dado que "Rotas sem escadas" está ativada
    E existe um alerta ativo de "Elevador fora de serviço" no único elevador até o 2º piso
    Quando calculo a rota até a Praça de Alimentação
    Então vejo a explicação "Não há caminho sem escadas até Praça de Alimentação por causa de um alerta da comunidade"
    E vejo qual alerta causa o bloqueio, com tipo, local e horário
    E vejo que "Rotas sem escadas" continua ativa
    E nenhuma rota com escada ou escada rolante é sugerida
    E posso tocar em "Pedir ajuda" para abrir o Ajuda+ com o local atual

  Cenário: Resolvido ou expirado deixa de afetar rotas (RF-A05, RN-A02, RN-A03)
    Dado que a rota desviava de um alerta de "Passagem interditada"
    Quando o alerta passa a "Resolvido" ou "Expirado"
    Então o marcador some do mapa de alertas ativos
    E um novo cálculo volta a poder usar o trecho
    E não aparece mais aviso desse alerta

  # ---------- Estados e erros ----------

  Cenário: Estado de carregamento dos alertas
    Quando abro o mapa e os alertas ainda estão sendo buscados
    Então vejo em texto "Carregando alertas da comunidade…"
    E o mapa e a navegação continuam utilizáveis enquanto isso

  Cenário: Erro ao enviar com "Tentar de novo"
    Dado que preenchi um relato
    Quando o envio falha
    Então vejo em texto que o alerta não foi publicado
    E o que preenchi continua guardado na tela
    E posso tocar em "Tentar de novo" sem preencher tudo outra vez
    E o alerta não aparece como publicado até o servidor confirmar

  Cenário: Erro de conexão ao atualizar alertas
    Dado que eu já via alertas no mapa
    Quando a conexão com o servidor cai
    Então vejo em texto que os alertas podem estar desatualizados e desde quando
    E os alertas que eu já tinha continuam visíveis
    E a atualização volta sozinha quando a conexão retorna

  Cenário: Modo simulado identificado quando não há servidor (RN-A07)
    Dado que o app foi aberto sem servidor de alertas, por exemplo na publicação estática
    Quando abro o mapa de alertas
    Então vejo em texto "Simulação: os alertas ficam só neste aparelho"
    E o identificador de simulação aparece também no formulário e no card do alerta
    E os alertas não são compartilhados com outras pessoas

  # ---------- Validação com duas sessões (Manual) ----------

  Cenário: Validação ponta a ponta com duas sessões (Manual)
    Dado o servidor de demonstração ligado
    E a sessão A no navegador do computador e a sessão B no celular na mesma Wi-Fi, ou duas janelas
    Quando A relata "Elevador fora de serviço" no elevador do Térreo
    Então B vê o marcador sem recarregar
    E uma rota sem escadas calculada em B muda ou explica que não há caminho
    Quando B toca em "Já foi resolvido"
    Então em A o alerta passa a "Resolvido" sem recarregar
    E a rota volta a usar o elevador

  # ---------- Acessibilidade (Manual) ----------

  Cenário: Leitor de tela no fluxo completo (Manual)
    Dado que o TalkBack está ativo
    Quando relato, abro um card, confirmo e marco como resolvido
    Então todos os botões têm nome falado claro
    E o leitor anuncia a publicação, os erros e o aviso de alerta no caminho
    E o leitor anuncia "não verificado" e, quando for o caso, "simulação"

  Cenário: Texto ampliado, contraste e movimento reduzido (Manual)
    Dado texto ampliado, alto contraste e movimento reduzido ativos
    Quando uso o formulário, o card e os avisos
    Então nenhum texto fica cortado
    E bloqueio e aviso continuam distinguíveis pela forma e pelo texto
    E não há animação obrigatória para entender um alerta
