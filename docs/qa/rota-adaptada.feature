# language: pt
# Rota adaptada à forma de circular (pedido do mentor, 14/11/2026)
# Rastreabilidade: RF03, RF12–RF15, RF18, RF48, RN01, RN02, RN03, RN04, RNF13
# Situação: em desenvolvimento / em validação. Rótulos de tela são prováveis e podem ser ajustados pelo front-end.
# Distâncias e tempos dependem dos dados fictícios de percursos.json; os cenários conferem a presença e a coerência
# dos valores, não números fixos.
#
# História
#   Como visitante que circula sobre rodas ou com apoio,
#   quero que o app troque a rota mais usada (escada rolante) por um caminho com elevador e me mostre o desvio,
#   para chegar à Praça de Alimentação sem encontrar degraus e sabendo quanto a mais vou percorrer.
#
# Princípios verificados: ninguém declara deficiência (RN01); a opção de circulação só liga recursos;
# restrição nunca é removida pelo app (RN04); simulações aparecem identificadas; nada depende só de cor.

Funcionalidade: Rota adaptada à forma de circular

  Contexto:
    Dado que estou na Entrada Principal, detectada pelo beacon BLE-01 (simulado)

  Cenário: Rota mais usada sem restrições vai pela escada rolante
    Dado que "Rotas sem escadas" e "Preferência por elevadores" estão desativadas
    Quando escolho "Praça de Alimentação"
    Então a rota usa a escada rolante do Térreo ao 2º piso
    E vejo o aviso "Tem degraus" em texto

  Cenário: Atalho "Sobre rodas" liga os recursos existentes (RF03, RN01)
    Dado que estou nas preferências
    Quando, em "Como você vai circular hoje?", escolho "Sobre rodas (cadeira de rodas, carrinho de bebê, mala)"
    Então "Rotas sem escadas" fica ativada
    E "Preferência por elevadores" fica ativada
    E posso desligar cada recurso individualmente depois

  Cenário: Atalho "Com apoio" liga os mesmos recursos (RF03, RN01)
    Dado que estou nas preferências
    Quando, em "Como você vai circular hoje?", escolho "Com apoio (andador, muletas, bengala)"
    Então "Rotas sem escadas" e "Preferência por elevadores" ficam ativadas

  Cenário: A opção de circulação não é guardada como identidade (RN01, RNF13)
    Dado que escolhi "Sobre rodas" em "Como você vai circular hoje?"
    Quando fecho e reabro o app
    Então as preferências salvas são apenas os recursos ("Rotas sem escadas", "Preferência por elevadores")
    E nenhum dado salvo registra a opção escolhida, tipo de deficiência ou equipamento usado
    E nenhuma tela pede diagnóstico ou comprovação

  Cenário: Comunicação continua independente da mobilidade (RN02)
    Dado que minhas preferências de comunicação estão como eu deixei
    Quando escolho "Sobre rodas" em "Como você vai circular hoje?"
    Então nenhuma preferência de comunicação é alterada

  Cenário: Rota adaptada dá a volta pelo elevador (RN03, RF14)
    Dado que "Rotas sem escadas" está ativada
    Quando escolho "Praça de Alimentação"
    Então a rota usa o elevador do Térreo ao 2º piso
    E nenhuma etapa usa escada rolante ou escada
    E a rota mostra "Sem escadas" e "Usa elevador"

  Cenário: Comparação entre rota mais usada e rota adaptada (RF14, RF18)
    Dado que "Rotas sem escadas" está ativada
    Quando escolho "Praça de Alimentação"
    Então vejo a comparação "Rota mais usada" e "Rota adaptada para você"
    E vejo em texto o que foi evitado, por exemplo "Evita: escada rolante"
    E vejo em texto o que substitui, por exemplo "Usa: elevador"
    E vejo quanto a mais em metros e em minutos, por exemplo "+ X m · + Y min"
    E a diferença é maior que zero e coerente com as distâncias das duas rotas
    E nenhuma diferença é indicada apenas por cor ou ícone

  Cenário: Sem desvio, não há comparação enganosa
    Dado que "Rotas sem escadas" está ativada
    Quando escolho um destino no Térreo cujo caminho mais usado já não tem degraus
    Então não vejo acréscimo de distância nem item "Evita"

  Cenário: Simular elevador em manutenção (RN04, RF48)
    Dado que "Rotas sem escadas" está ativada
    E escolhi "Praça de Alimentação"
    Quando toco em "Simular elevador em manutenção"
    Então vejo o aviso identificado como simulação, por exemplo "Simulação: elevador em manutenção"
    E o app recalcula a rota
    E, como não há outro caminho sem escadas, vejo "Não há caminho sem escadas até Praça de Alimentação."
    E vejo que "Rotas sem escadas" continua ativa
    E posso tocar em "Pedir ajuda" para abrir o Ajuda+ com o local atual
    E posso escolher outro destino ou revisar minhas preferências

  Cenário: A restrição nunca é retirada pelo app (RN04)
    Dado que a simulação de elevador em manutenção está ativa
    Quando volto à tela de rota
    Então nenhuma rota com escada rolante ou escada é sugerida como "adaptada"
    E só eu posso desligar "Rotas sem escadas" nas preferências

  Cenário: Encerrar a simulação de manutenção
    Dado que a simulação de elevador em manutenção está ativa
    Quando encerro a simulação
    Então a rota pelo elevador volta a ser oferecida
    E o aviso de simulação desaparece

  Cenário: Leitor de tela e texto ampliado na comparação (Manual)
    Dado que o TalkBack e o texto ampliado estão ativos
    Quando percorro a comparação e o aviso de manutenção
    Então o leitor anuncia o que foi evitado, o que substitui, os metros e minutos a mais e a palavra "simulação"
    E nenhum texto fica cortado

  Cenário: Validação com pessoas usuárias (Manual, pendente)
    Dado que pessoas que circulam com cadeira de rodas, carrinho ou apoio usam o fluxo
    Quando seguem a rota adaptada até a Praça de Alimentação
    Então registramos se entenderam o desvio e se o acréscimo informado foi útil
    E os resultados são subsídio para decisão da equipe, não aprovação automática
