# language: pt
# Etapa 3a — "Para onde você quer ir?" e resumo da rota (MUD-01)
# Rastreabilidade: RF07–RF15, RF18, RF51, RN02, RN03, RN04, RN06, RN09, RN10, RNF08
# Automatizados em app/test/destino_test.dart e app/test/data/rotas_test.dart.

Funcionalidade: Escolher um destino e ver a rota

  Contexto:
    Dado que estou na Entrada Principal, detectada pelo beacon BLE-01 (simulado)

  Cenário: Depois das preferências vem a escolha do destino
    Dado que terminei de ajustar minhas preferências
    Quando toco em "Continuar"
    Então vejo "Para onde você quer ir?"
    E vejo "Você está aqui" com o nome do ponto, o piso e o beacon simulado

  Cenário: Atalho grande para banheiro acessível
    Quando toco em "Banheiro acessível"
    Então vejo os banheiros acessíveis do Térreo e do 2º piso
    E o mais perto aparece primeiro

  Cenário: Busca sem acento (RF07)
    Quando busco "fraldario"
    Então vejo "Espaço Família"

  Cenário: Busca sem resultado (RF09)
    Quando busco "xyz"
    Então vejo "Nada encontrado"
    E posso tocar em "Limpar busca e filtros"

  Cenário: Filtro por piso (RF08)
    Quando escolho o piso "2º piso"
    Então vejo apenas locais do 2º piso

  Cenário: Rota sem escadas (RN03)
    Dado que ativei "Rotas sem escadas"
    Quando escolho "Praça de Alimentação"
    Então a rota mostra "Sem escadas" e "Usa elevador"
    E nenhuma etapa fala em degraus

  Cenário: Nenhuma rota compatível (RN04, RF15)
    Dado que ativei "Rotas sem escadas"
    Então a "Galeria do Mezanino" aparece como "Só há caminho com escadas"
    Quando escolho "Galeria do Mezanino"
    Então vejo "Não há caminho sem escadas até Galeria do Mezanino."
    E vejo que minha preferência continua ativa
    E posso escolher outro destino, pedir ajuda ou revisar minhas preferências

  Cenário: Aviso de degraus quando não peço rota sem escadas
    Dado que "Rotas sem escadas" está desativada
    Quando escolho "Sabor da Terra"
    Então a rota mostra "Tem degraus"
    E vejo a sugestão de ativar "Rotas sem escadas"

  Cenário: Preferência por elevador muda a rota
    Dado que ativei "Preferência por elevadores"
    Quando escolho "Sabor da Terra"
    Então a rota usa o elevador, e não a escada rolante

  Cenário: Simular outro ponto (RF51, RN09)
    Quando toco em "Trocar" e escolho "Praça de Alimentação"
    Então "Você está aqui" mostra o 2º piso e o beacon BLE-26 (simulado)

  Cenário: Informação desconhecida no destino (RNF08)
    Quando escolho "Livraria Página"
    Então vejo "Horário: Não informado"

  Cenário: Passo a passo em texto (RF18)
    Quando escolho qualquer destino com rota
    Então vejo as etapas numeradas, em texto, com o ponto e o piso de cada uma

  Cenário: Leitor de tela e texto ampliado na busca (Manual)
    Dado que o TalkBack e o texto ampliado estão ativos
    Quando percorro a tela "Para onde você quer ir?"
    Então os atalhos, filtros e resultados são lidos com nome e estado
    E nenhum texto fica cortado
