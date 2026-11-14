# language: pt
# Etapa 3b — Paradas, bússola guiada pelo mapa e mapa interativo (MUD-01, MUD-02)
# Rastreabilidade: RF17–RF22, RF48, RN03, RN04, RN09, RNF04
# Automatizados em app/test/navegacao_test.dart e app/test/data/viagem_test.dart.

Funcionalidade: Navegar com paradas, bússola e mapa

  Contexto:
    Dado que estou na Entrada Principal, detectada pelo beacon BLE-01 (simulado)
    E que a preferência "Rotas sem escadas" está ativa

  # Paradas no estilo dos apps de transporte (MUD-02)

  Cenário: Ir ao elevador e depois à Praça de Alimentação
    Quando escolho "Elevadores — Térreo"
    E toco em "Adicionar outra parada"
    Então vejo "Qual a próxima parada?" com as distâncias contadas a partir do elevador
    Quando escolho "Praça de Alimentação"
    Então vejo "Parada 1: Elevadores — Térreo" e "Destino final: Praça de Alimentação"
    E o passo a passo aparece separado por parada
    E o resumo mostra "2 paradas" e a distância total

  Cenário: Reordenar e remover paradas
    Dado uma rota com as paradas "Elevadores — Térreo" e "Praça de Alimentação"
    Quando toco em "Mover Praça de Alimentação para antes"
    Então a Praça de Alimentação vira a parada 1 e a rota é recalculada
    Quando removo a Praça de Alimentação
    Então volta a existir um único destino

  Cenário: Parada sem caminho compatível (RN04)
    Dado uma rota com paradas
    Quando adiciono "Galeria do Mezanino", que só tem acesso por escada
    Então essa parada é marcada "Sem caminho compatível até aqui"
    E minha preferência "Rotas sem escadas" continua ativa
    E posso tocar em "Remover a parada Galeria do Mezanino"

  Cenário: Limite de paradas
    Dado uma rota com 5 paradas
    Então o botão mostra "Limite de 5 paradas" e fica desativado

  # Navegação (T06)

  Cenário: Bússola guiada pelo mapa
    Quando inicio a navegação
    Então vejo a instrução da etapa em texto grande e onde estou
    E a seta aponta para o próximo ponto no mapa (para cima = topo do mapa)
    E a tela avisa que a seta não usa a bússola do celular
    Em troca de piso, a seta dá lugar ao ícone do elevador ou da escada

  Cenário: Chegada a cada beacon (simulado)
    Quando toco em "Simular chegada: <próximo ponto>"
    Então "Você está em" passa a ser o próximo ponto
    E a barra de progresso e os metros restantes são atualizados

  Cenário: Parada intermediária espera o visitante
    Quando chego aos Elevadores — Térreo
    Então vejo "Você chegou à parada 1"
    E não aparece mais "Simular chegada" até eu tocar em "Seguir para Praça de Alimentação"

  Cenário: Chegada ao destino final
    Quando chego à Praça de Alimentação
    Então vejo "Você chegou!" e "Rota concluída"
    E "Escolher novo destino" me leva de volta a "Para onde você quer ir?"

  # Mapa interativo

  Cenário: Zoom e "Você está aqui"
    Quando abro a aba "Mapa"
    Então vejo o piso onde estou marcado "(você)", a rota desenhada e o ponto "Você"
    E posso aproximar, afastar e centralizar por botões (além do gesto de pinça)

  Cenário: Ver outro piso e voltar
    Quando escolho o piso "2º piso"
    Então vejo "Vendo o 2º piso. Você está no Térreo."
    Quando toco em "Ver meu piso"
    Então o mapa volta ao Térreo

  Cenário: O mapa acompanha a troca de piso
    Quando chego ao 2º piso de elevador
    Então o mapa passa a mostrar o 2º piso automaticamente

  # Modo GPS

  Cenário: Instrução no estilo de banner de GPS
    Quando a navegação está em andamento
    Então vejo o ícone da manobra (seguir, virar, elevador, escada), a distância em metros
    E a linha "Depois" com a manobra seguinte
    E "Faltam … m · … min · chegada às HH:MM"

  Cenário: O mapa segue e gira na direção da caminhada
    Quando abro a aba "Mapa"
    Então o mapa aproxima no meu ponto, com a seta "Você" no terço de baixo
    E o mapa gira para a direção da caminhada ficar para cima
    Quando simulo a chegada ao próximo beacon
    Então a seta desliza até o novo ponto e o mapa gira para a próxima direção
    E com movimento reduzido a seta pula direto, sem animação

  Cenário: Norte do mapa para cima
    Quando toco na bússola do mapa
    Então o mapa para de girar e o norte do mapa fica para cima
    Quando toco de novo
    Então o mapa volta a girar na direção da caminhada

  Cenário: Mapa solto e Recentralizar
    Quando arrasto ou pinço o mapa, ou toco em "Ver a rota inteira"
    Então o mapa para de me seguir e aparece "Recentralizar"
    Quando toco em "Recentralizar" ou chego ao próximo beacon
    Então o mapa volta a me seguir

  Cenário: Mapa acessível a leitores de tela (RNF04)
    Então o mapa tem uma descrição em texto com o piso, onde estou,
      os pontos da rota naquele piso e o próximo ponto
