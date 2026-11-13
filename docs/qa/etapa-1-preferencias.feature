# language: pt
# Etapa 1 — Boas-vindas (T01) e Preferências de acessibilidade (T02)
# Rastreabilidade: RF01, RF03, RF04, RN01, RN02, RNF01, RNF04, RNF07, RNF12
# Automatizados em app/test/widget_test.dart, exceto onde indicado "Manual".

Funcionalidade: Boas-vindas e preferências de acessibilidade
  Como visitante do shopping
  Quero escolher os recursos que me ajudam, sem declarar deficiência
  Para que o aplicativo se adapte a mim

  Cenário: Apresentação do Acessa+ (RF01)
    Dado que abro o aplicativo pela primeira vez
    Então vejo o nome "Acessa+" e a frase "Acessibilidade que conecta pessoas."
    E vejo os pilares "Comunicação Universal", "Navegação Viva" e "Ajuda+"
    E vejo um aviso de que o protótipo usa dados simulados

  Cenário: Preferências sem diagnóstico (RN01)
    Dado que estou na tela de boas-vindas
    Quando toco em "Começar"
    Então vejo a tela "Minha acessibilidade"
    E vejo que não é preciso declarar nenhuma deficiência
    E nenhuma opção pede diagnóstico

  Cenário: Preferências começam desativadas
    Dado que abro as preferências pela primeira vez
    Então vejo "Nenhum recurso ativo"

  Cenário: Estado do interruptor não depende só da cor (RNF04)
    Dado que estou na tela "Minha acessibilidade"
    Quando ativo "Texto ampliado"
    Então o cartão mostra o texto "Ativado"
    E o leitor de tela recebe o interruptor como ligado
    E o contador anuncia "1 recurso ativo"

  Cenário: Texto ampliado altera a experiência (RF04)
    Dado que estou na tela "Minha acessibilidade"
    Quando ativo "Texto ampliado"
    Então todo o texto do aplicativo fica 30% maior que a escala do sistema

  Cenário: Alto contraste altera a experiência (RF04)
    Dado que estou na tela "Minha acessibilidade"
    Quando ativo "Alto contraste"
    Então o fundo fica preto, o texto branco e os destaques amarelos

  Cenário: Comunicação e mobilidade são independentes (RN02)
    Dado que nenhuma preferência está ativa
    Quando ativo "Comunicação por texto"
    Então "Rotas sem escadas" e "Preferência por elevadores" continuam desativadas
    Quando ativo "Rotas sem escadas"
    Então "Comunicação por texto" continua ativada
    E "Preferência por elevadores" continua desativada

  Cenário: Desativar todas as preferências
    Dado que ativei "Alto contraste" e "Rotas sem escadas"
    Quando toco em "Desativar todas"
    Então vejo "Nenhum recurso ativo"

  Cenário: Movimento reduzido pelo sistema
    Dado que o aparelho pede redução de movimento
    Quando abro a tela "Minha acessibilidade"
    Então todo o conteúdo aparece sem animação

  Cenário: Redução de estímulos desliga animações (Manual)
    Dado que estou na tela "Minha acessibilidade"
    Quando ativo "Redução de estímulos"
    Então as cores ficam mais suaves
    E nenhuma animação acontece ao trocar de tela ou de interruptor

  Cenário: Requisitos básicos de acessibilidade da interface (RNF01)
    Dado que estou na tela de boas-vindas ou de preferências
    Então todos os alvos de toque têm pelo menos 48 dp
    E todos os controles têm rótulo para leitor de tela
    E o texto atende ao contraste mínimo no tema padrão e no alto contraste

  Cenário: Leitor de tela no aparelho (Manual — RNF02, RNF12)
    Dado que o TalkBack está ativo em um aparelho Android
    Quando percorro as telas de boas-vindas e preferências
    Então cada cartão de preferência é lido como um interruptor com título, descrição e estado
    E a ordem de leitura segue a ordem visual

  # --- Rodada 2: paleta Noite neon, mapa vivo e prévia ao vivo ---

  Cenário: Mapa vivo conta o problema (RF01, RNF04)
    Dado que abro o aplicativo
    Então vejo um mapa em que o caminho encontra uma escada, desvia pelo elevador e chega ao destino
    E os pontos "Entrada", "Escada", "Elevador" e "Destino" têm rótulos em texto
    E o leitor de tela lê a descrição do mapa

  Cenário: Mapa vivo com movimento reduzido (Manual)
    Dado que o aparelho pede redução de movimento
    Quando abro o aplicativo
    Então o mapa aparece pronto, sem animação

  Cenário: Título em tela estreita
    Dado que uso um celular com 360 dp de largura
    Quando abro o aplicativo
    Então vejo "Acessibilidade que conecta pessoas." sem palavras quebradas

  Cenário: Prévia ao vivo das preferências
    Dado que estou na tela "Minha acessibilidade"
    E vejo "Rota mais curta" na prévia
    Quando ativo "Rotas sem escadas"
    Então a prévia mostra "Sem escadas"

  Cenário: Troca de tema em círculo (Manual)
    Dado que estou na tela "Minha acessibilidade"
    Quando ativo "Alto contraste"
    Então o novo tema se espalha em círculo a partir do interruptor
    E com "Redução de estímulos" ativa a troca é instantânea
